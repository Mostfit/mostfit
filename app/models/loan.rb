class Loan
  include DataMapper::Resource
  after :save,    :update_history  # also seems to do :update
#   after :create,  :update_history
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
  validates_is_primitive :scheduled_disbursal_date, :scheduled_first_payment_date, :approved_on  # :disbursal_date (opt.)
  

  # this is the method used for creating payments, not directly on the Payment class
  # for +input+ it allows either a "total" amount as Fixnum or an array with
  # principal[0] and interest[1].
  # TODO: destroying payments by the Loan class, and update_history accordingly
  # TODO: some kind of validation
  def repay(input, user, received_on, received_by)
    # this is the way to repay loans, _not_ directly on the Payment model
    # this to allow validations on the Payment to be implemented in (subclasses of) the Loan
    unless input.is_a? Array or input.is_a? Fixnum
      raise "the input argument of Loan#repay should be of class Fixnum or Array"
    end

    interest, principal = 0, 0
    if input.is_a? Fixnum  # in case only one amount is specified
      # interest is paid first, the rest goes in as principal
      total        = input.to_i
      interest_due = (interest_overpaid_on(received_on) > 0) ? 0 : interest_overpaid_on(received_on).abs 
      interest     = [interest_due, total].min  # never more than total
      principal    = total - interest
    elsif input.is_a? Array  # in case principal and interest are specified separately
      principal, interest = input[0].to_i, input[1].to_i
    end

    raise ValidationError unless StaffMember.first(:id => received_by, :active => true)
    payment = Payment.new(:loan_id => self.id, :user_id => user.id,
      :received_on => received_on, :received_by_staff_id => received_by,
      :principal => principal, :interest => interest)
    save_status = payment.save
    update_history if save_status  # update the history is we saved a payment
    [save_status, payment]  # return the success boolean and the payment object itself for further processing
  end


  # these 2 methods define the pay back scheme
  # typically reimplemented in subclasses
  def scheduled_principal_for_installment(number)
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

  # the 'grande totale' of what the client has to pay back for this loan
  # used in many places
  def total_to_be_received
    (self.amount.to_f * (1 + self.interest_rate)).round
  end

  # the following methods basically count the payments
  # next two methods use simple caching
  # it works because objects live short (usualy only within the scope of one request)
  def principal_received_up_to(date)
    payments_received_up_to(date)[0]
  end
  def interest_received_up_to(date)
    payments_received_up_to(date)[1]
  end
  def total_received_up_to(date)
    payments_received_up_to(date)[2]
  end  
  # private??
  # returns an array with as contents sums of the principal[0], interest[1] and total[2]
  # proper optimization, and good example of falling back to SQL
  # keeps the cache for principal_received_up_to/interest_received_up_to/total_received_up_to
  def payments_received_up_to(date)
    return @summed_payments_cache[date] if @summed_payments_cache and @summed_payments_cache[date]
    @summed_payments_cache ||= {}
    @summed_payments_cache[date] = repository.adapter.query(%Q{
      SELECT SUM("principal"), SUM("interest"), SUM("principal" + "interest") AS "total"
      FROM "payments"
      WHERE ("deleted_at" IS NULL)
        AND ("loan_id" = #{self.id})
        AND received_on <= "#{date}"})[0].to_a.map { |x| x.nil? ? 0 : x }  # nil -> 0
  end

  # these three methods return the scheduled outstanding amount for any date
  # these 3 are so purely calculated -- no calls to its payments or loan_history)
  def scheduled_outstanding_principal_on(date)  # typically reimplemented in subclasses
    (amount.to_i / number_of_installments * number_of_installments_before(date)).round
  end
  def scheduled_outstanding_interest_on(date)  # typically reimplemented in subclasses
    (interest_rate * amount / number_of_installments * number_of_installments_before(date)).round
  end
  def scheduled_outstanding_total_on(date)
    scheduled_outstanding_principal_on(date) + scheduled_outstanding_interest_on(date)
  end

  # 2 sets of convenience methods
  def principal_overpaid_on(date)  # negative values mean shortfall
    principal_received_up_to(date) - scheduled_outstanding_principal_on(date)
  end
  def interest_overpaid_on(date)
    interest_received_up_to(date) - scheduled_outstanding_interest_on(date)
  end
  def total_overpaid_on(date)
    total_received_up_to(date) - scheduled_outstanding_total_on(date)
  end
  def actual_outstanding_principal_on(date)
    scheduled_outstanding_principal_on(date) - principal_overpaid_on(date)
  end
  def actual_outstanding_interest_on(date)
    scheduled_outstanding_interest_on(date) - interest_overpaid_on(date)
  end
  def actual_outstanding_total_on(date)
    scheduled_outstanding_total_on(date) + total_overpaid_on(date)
  end


  # used by the views to quickly get an overview of the "calculated schedule"
  # this schedule does not need any further queries for payments or the loan_history
  # TODO: MAYBE IT SHOULD? (i think it should --  cies)
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

  # the installment dates
  # used by the grap_data controller
  def installment_dates
    (0..(number_of_installments-1)).to_a.map { |x| shift_date_by_installments(scheduled_first_payment_date, x) }
  end

#   # unused so far
#   def scheduled_payment_date_for_installment(number)
#     raise "number shoul be 1 or larger, got #{number}" if number < 1
#     if number == 1
#       scheduled_first_payment_date
#     else
#       shift_date_by_installments(scheduled_first_payment_date, number-1)
#     end
#   end

  # how is this loan repayed? principal/interest separate, aggregated or allow either way
  # at some point this should have effect on the view (1 or 2 fields)
  def repayment_style
    :allow_both   # one of [:separate, :aggregated, :allow_both]
  end

#   def approved?(date = Date.today);    not self.disbursal_date.blank?; end  # nice but not yet needed it seems
#   def disbursed?(date = Date.today);   not self.disbursal_date.blank?; end
#   def written_off?(date = Date.today); not self.written_off_on.blank?; end

  # this method returns one of [nil, :approved, :disbursed, :repaid, :written_off]
  def status(date = Date.today)
    return nil          if approved_on >  date  # non existant
    return :approved    if approved_on <= date and not (disbursal_date and disbursal_date <= date)
    return :written_off if (written_off_on and written_off_on <= date)
    total_received_up_to(date) >= total_to_be_received ? :repaid : :disbursed
  end



  # the number of payment dates before 'date' (if date is a payment 'date' it is counted in)
  # used to calculate the outstanding value
  def number_of_installments_before(date)
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

  # the arithmic of shifting by the installment_frequency (especially months is tricky)
  # used by many other methods
  def shift_date_by_installments(date, number)
    raise "number should be 0 or larger, got #{number}" if number < 0
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

  # this method returns the last date the loan history makes sense
  # used by +update_history+ for knowing when to stop.
  # (note: this is often a date in the future -- huh?!)
  def last_loan_history_date
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

  # neat trick.. returns an Array with all subclasses of this model
  # used in loan type selection.
  def self.subclasses; @subclasses ||= Array.new; end
  def self.inherited(subclass); subclasses << subclass; end
  
#   private

  ## validations: read their method name and error to see what they do.
  def approved_before_disbursed_before_written_off?
    parse_dates
    if disbursal_date and approved_on < disbursal_date
      [false, "Cannot be disbursed before it is approved"]
    elsif disbursal_date and written_off_on and disbursal_date < written_off_on
      [false, "Cannot be written off before it is disbursed"]
    end
    true
  end
  def properly_written_off?
    parse_dates
    return true if (written_off_on and written_off_by_staff_id) or
      (!written_off_on and !written_off_by_staff_id)
    [false, "written_off_on and written_off_by properties have to be (un)set together"]
  end
  def properly_disbursed?
    parse_dates
    return true if (disbursal_date and disbursed_by_staff_id) or
      (!disbursal_date and !disbursed_by_staff_id)
    [false, "disbursal_date and disbursed_by properties have to be (un)set together"]
  end


  ## FIXME
  ## trying to solve a problem with the (auto) validations on empty dates
  def parse_dates
    self.approved_on    = Loan::parse_date(approved_on)
    self.disbursal_date = Loan::parse_date(disbursal_date)
    self.written_off_on = Loan::parse_date(written_off_on)
  end
  def self.parse_date(date)
    return date if date.is_a? Date
    return date.to_time.to_date if date.is_a? DateTime
    return Date.parse(date) if date.is_a? String
  rescue
    nil
  end

  # THE RUNNER.. this methods refreshes the history(/future) of this lone when
  # changes have been made to it, or its payments. gets called by hooks
  # the task of updating the history may take some time and it therefor put
  # the the Merb::Dispatcher.work_queue (using Merb.run_later)
  def update_history
    Merb.run_later { update_history_now }  # i just love procrastination
  end
  def update_history_now
    start_date = approved_on  # start date
    end_date   = last_loan_history_date  # end date
    date       = start_date
    run_number = (LoanHistory.max(:run_number) or 0) + 1
    t0         = Time.now
    Merb.logger.info! "Start Loan#history_update for loan ##{self.id} (#{start_date} - #{end_date}), at #{t0}"
    while date <= end_date
      puts ">>>>>>>>> write_for(#{[run_number, date].inspect})"
      LoanHistory::write_for(self, run_number, date)
      date += 1
    end
    t1 = Time.now
    secs = (t1 - t0).round
    Merb.logger.info! "Finished Loan#history_update for loan ##{self.id} (#{start_date} - #{end_date}), in #{secs} secs (#{format("%.3f", secs.to_f/(end_date-start_date))} secs/record), at #{t1}"
  end
end

class DefaultLoan < Loan
  # This is the "Default" loan type. It is nothing better of worse than its parent.
  # That explains the emptyness
end

class A50Loan < Loan
  # a fine example of a subclassing (if it was finished)

  # so we have to implement some thing different here to show that it is possible :-P
end

