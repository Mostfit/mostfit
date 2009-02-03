class Loan
  include DataMapper::Resource
  after :save,    :update_history  # also seems to do :update
  after :create,  :update_history
  after :destroy, :update_history
  
  property :id,                             Serial
  property :discriminator,                  Discriminator, :nullable => false
  property :amount,                         Integer, :nullable => false  # see helper for formatting
  property :interest_rate,                  Float, :nullable => false
  property :installment_frequency,          Enum[:daily, :weekly, :monthly], :nullable => false
  property :number_of_installments,         Integer, :nullable => false
  property :scheduled_first_payment_date,   Date, :nullable => false  # arbitrary date for installment number 0
  property :approved_on,                    Date, :nullable => false
  property :scheduled_disbursal_date,       Date, :nullable => false
  property :disbursal_date,                 Date  # not disbursed when nil
  property :created_at,                     DateTime
  property :updated_at,                     DateTime
  property :written_off_on,                 Date

  belongs_to :client
  belongs_to :approved_by,    :child_key => [:approved_by_staff_id],    :class_name => 'StaffMember'
  belongs_to :disbursed_by,   :child_key => [:disbursed_by_staff_id],   :class_name => 'StaffMember'
  belongs_to :written_off_by, :child_key => [:written_off_by_staff_id], :class_name => 'StaffMember'
  has n, :payments
  has n, :history, :class_name => 'LoanHistory'

  validates_with_method  :approved_before_disbursed_before_written_off?
  validates_with_method  :properly_written_off?
  validates_with_method  :properly_disbursed?
  validates_present      :approved_by_staff_id
  validates_is_primitive :disbursal_date, :scheduled_disbursal_date, :scheduled_first_payment_date, :approved_on
  
  # TODO: destroying payments by the Loan class, and update_history accordingly

  def repay(input, user, received_on, received_by)  # TODO: some kind of validation
    # this is the way to repay loans, _not_ directly on the Payment model
    # this to allow validations on the Payment to be implemented in (subclasses of) the Loan
    unless input.is_a? Array or input.is_a? Fixnum
      raise "the input argument of Loan#repay should be of class Fixnum or Array"
    end

    interest, principal = 0, 0
    if input.is_a? Fixnum  # in case only one amount is specified
      # interest is paid first, the rest goes in as principal
      total = input.to_i
      interest  = [interest_due_on(received_on), total].min  # just input when not sufficient for interest due 
      principal = total - interest
    elsif input.is_a? Array  # in case principal and interest are specified separately
      principal, interest = input[0].to_i, input[1].to_i
    end

    payment = Payment.new(:loan_id => self.id, :user_id => user.id,
      :received_on => received_on, :received_by_staff_id => received_by,
      :principal => principal, :interest => interest)
    save_status = payment.save
    update_history if save_status  # update the history is we saved a payment
    [save_status, payment]  # return the success boolean and the payment object itself for further processing
  end



  def scheduled_principal_for_installment(number)  # typically reimplemented in subclasses
    # number unused in this implentation, subclasses may decide differently
    # therefor always supply number, so it works for all implementations
    raise "number out of range, got #{number}" if number < 0 or number > number_of_installments - 1
    amount.to_f / number_of_installments
  end

  def scheduled_interest_for_installment(number)  # typically reimplemented in subclasses
    # number unused in this implentation, subclasses may decide differently
    # therefor always supply number, so it works for all implementations
    raise "number out of range, got #{number}" if number < 0 or number > number_of_installments - 1
    interest_rate * amount / number_of_installments
  end


  def total_to_be_received
    (self.amount.to_f * (1 + self.interest_rate)).round
  end

  def total_scheduled_principal_on(date)  # typically reimplemented in subclasses
    (amount.to_i / number_of_installments * number_of_installments_before(date)).round
  end
  def total_scheduled_interest_on(date)  # typically reimplemented in subclasses
    (interest_rate * amount / number_of_installments * number_of_installments_before(date)).round
  end
  def total_scheduled_on(date)
    total_scheduled_principal_on(date) + total_scheduled_interest_on(date)
  end

  # next two methods use simple caching
  # it works because objects live short (usualy only within the scope of one request)
  def total_received_principal_on(date)
    return @trp_cache[date] if @trp_cache and @trp_cache[date]
    @trp_cache ||= {}
    @trp_cache[date] = (Payment.sum(:principal, :conditions => ['received_on <= ? AND loan_id = ?', date, self.id]) or 0)
  end
  def total_received_interest_on(date)
    return @tri_cache[date] if @tri_cache and @tri_cache[date]
    @tri_cache ||= {}
    @tri_cache[date] = (Payment.sum(:interest, :conditions => ['received_on <= ? AND loan_id = ?', date, self.id]) or 0)
  end
  def total_received_on(date)
    total_received_principal_on(date) + total_received_interest_on(date)
  end  

  def principle_difference_on(date)
    total_scheduled_principal_on(date) - total_received_principal_on(date)
  end
  def interest_difference_on(date)
    total_scheduled_interest_on(date) - total_received_interest_on(date)
  end
  def total_difference_on(date)
    principle_difference_on(date) + interest_difference_on(date)
  end

  def principal_due_on(date)
    [principle_difference_on(date), 0].max
  end
  def interest_due_on(date)
    [interest_difference_on(date), 0].max
  end
  def total_due_on(date)
    principal_due_on(date) + interest_due_on(date)
  end


  def payment_schedule
    schedule = []
    number_of_installments.times do |number|
      schedule << {
        :date      => shift_date_by_installments(scheduled_first_payment_date, number),
        :principal => scheduled_principal_for_installment(number),
        :interest  => scheduled_interest_for_installment(number) }
    end
    schedule
  end

  def scheduled_payment_dates
    dates = []
    number_of_installments.times do |number|
      dates << shift_date_by_installments(scheduled_first_payment_date, number)
    end
    dates
  end

  def scheduled_payment_date_for_installment(number)
    raise "Loan#scheduled_payment_date_for_installment: number < 1, got #{number}" if number < 1
    if number == 1
      scheduled_first_payment_date
    else
      shift_date_by_installments(scheduled_first_payment_date, number-1)
    end
  end

  def repayment_style
    # how is this loan repayed? principal/interest separate, aggregated or allow either way
    # at some point this should have effect on the view (1 or 2 fields)
    :allow_both   # one of [:separate, :aggregated, :allow_both]
  end

#   def approved?(date = Date.today);    not self.disbursal_date.blank?; end  # nice but not yet needed it seems
#   def disbursed?(date = Date.today);   not self.disbursal_date.blank?; end
#   def written_off?(date = Date.today); not self.written_off_on.blank?; end

  def status(date = Date.today)
    return nil          if approved_on >  date  # non existant
    return :approved    if approved_on <= date and not (disbursal_date and disbursal_date <= date)
    return :written_off if (written_off_on and written_off_on <= date)
    total_received_on(date) >= total_to_be_received ? :repaid : :disbursed
  end

  # private
  def number_of_installments_before(date)
    # the number of payment dates before 'date' (if date is a payment 'date' it is counted in)
    return 0 if date < scheduled_first_payment_date
    result = case installment_frequency
      when :daily
      then (date - scheduled_first_payment_date).to_f.floor + 1
      when :weekly
      then ((date - scheduled_first_payment_date).to_f / 7).floor + 1
      when :monthly
      then start_day, start_month = scheduled_first_payment_date.day, scheduled_first_payment_date.month
           end_day, end_month = date.day, date.month
           end_month - start_month + (start_day >= end_day ? 0 : 1)
      else raise "Strange period you got.."
    end
    [result, number_of_installments].min  # never return more than the number_of_installments
  end

  def shift_date_by_installments(date, number)
    raise "Loan#shift_date_by_installments: number < 0, got #{number}" if number < 0
    return date if number == 0
    case installment_frequency
      when :daily
        return date + number
      when :weekly
        return date + number * 7
      when :monthly
        new_month = date.month + number
        new_year  = date.year
        while new_month > 12
          new_year  += 1
          new_month -= 12
        end
        month_lengths = [nil, 31, (Time.gm(new_year, new_month).to_date.leap? ? 29 : 28), 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        new_day = date.day > month_lengths[new_month] ? month_lengths[new_month] : date.day
        return Time.gm(new_year, new_month, new_day).to_date
      else
        raise "Strange period you got.."
    end
  end



#   private
  def approved_before_disbursed_before_written_off?
    if disbursal_date and approved_on > disbursal_date
      [false, "Cannot be disbursed before it is approved"]
    elsif disbursal_date and written_off_on and disbursal_date > written_off_on
      [false, "Cannot be written off before it is disbursed"]
    end
    true
  end

  def properly_written_off?
    return true if (written_off_on and written_off_by_staff_id) or
      (!written_off_on and !written_off_by_staff_id)
    [false, "written_off_on and written_off_by properties have to be (un)set together"]
  end

  def properly_disbursed?
    return true if (disbursal_date and disbursed_by_staff_id) or
      (!disbursal_date and !disbursed_by_staff_id)
    [false, "disbursal_date and disbursed_by properties have to be (un)set together"]
  end

  def last_loan_history_date
    # this method return the last date the loan history makes sense
    # this can be a date in the future! (huh?!!)
    s = status  # TODO: replace with case-when constuct
    scheduled_repaid_on = shift_date_by_installments(scheduled_first_payment_date, number_of_installments)
    if s.nil?
      return nil
    elsif s == :approved
      return scheduled_repaid_on
    elsif s == :disbursed
      return [scheduled_repaid_on, Date.today].max
    elsif s == :repaid
      last_payment_received_on = self.payments.first(:order => [:received_on.desc]).received_on
      return [scheduled_repaid_on, last_payment_received_on].max
    elsif s == :written_off
      return [scheduled_repaid_on, written_off_on].max
    end
  end

  def update_history
    Merb.run_later do
      date = approved_on  # start date
      last_date = last_loan_history_date  # end date
      run_number = (LoanHistory.max(:run_number) or 0) + 1
      t0 = Time.now
      Merb.logger.info! "Start Loan#history_update for loan ##{self.id} (#{approved_on} - #{last_date}), at #{t0}"
      while date <= last_loan_history_date
        LoanHistory::write_for(self, run_number, date)
        date += 1
      end
      t1 = Time.now
      secs = (t1 - t0).round
      Merb.logger.info! "Finished Loan#history_update for loan ##{self.id} (#{approved_on} - #{last_date}), in #{secs} secs (#{format("%.3f", secs.to_f/(last_date-approved_on))} secs/record), at #{t1}"
    end
  end
end

class A50Loan < Loan
  
end