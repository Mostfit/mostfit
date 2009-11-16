class Loan
  include DataMapper::Resource
  before :valid?,  :parse_dates
  after  :save,    :update_history  # also seems to do updates
  after  :destroy, :update_history

  attr_accessor :history_disabled  # set to true to disable history writing by this object
  attr_accessor :interest_percentage  # set to true to disable history writing by this object
  
  property :id,                             Serial
  property :discriminator,                  Discriminator, :nullable => false, :index => true
  property :amount,                         Integer, :nullable => false, :index => true  # see helper for formatting
  property :interest_rate,                  Float, :nullable => false, :index => true
  property :installment_frequency,          Enum.send('[]', *INSTALLMENT_FREQUENCIES), :nullable => false, :index => true
  property :number_of_installments,         Integer, :nullable => false, :index => true
  property :scheduled_disbursal_date,       Date, :nullable => false, :auto_validation => false, :index => true
  property :scheduled_first_payment_date,   Date, :nullable => false, :auto_validation => false, :index => true
  property :applied_on,                     Date, :nullable => false, :auto_validation => false, :index => true
  property :approved_on,                    Date, :auto_validation => false, :index => true
  property :rejected_on,                    Date, :auto_validation => false, :index => true
  property :disbursal_date,                 Date, :auto_validation => false, :index => true
  property :written_off_on,                 Date, :auto_validation => false, :index => true
  property :validated_on,                   Date, :auto_validation => false, :index => true

  property :validation_comment,             Text
  property :created_at,                     DateTime, :index => true
  property :updated_at,                     DateTime, :index => true
  property :loan_product_id,                Integer,  :index => true

  property :applied_by_staff_id,            Integer, :nullable => true, :index => true 
  property :approved_by_staff_id,           Integer, :nullable => true, :index => true 
  property :rejected_by_staff_id,           Integer, :nullable => true, :index => true 
  property :disbursed_by_staff_id,          Integer, :nullable => true, :index => true 
  property :written_off_by_staff_id,        Integer, :nullable => true, :index => true 
  property :validated_by_staff_id,          Integer, :nullable => true, :index => true 
  # associations
  belongs_to :client
  belongs_to :funding_line
  belongs_to :applied_by,     :child_key => [:applied_by_staff_id],     :model => 'StaffMember'
  belongs_to :approved_by,    :child_key => [:approved_by_staff_id],    :model => 'StaffMember'
  belongs_to :rejected_by,    :child_key => [:rejected_by_staff_id],    :model => 'StaffMember'
  belongs_to :disbursed_by,   :child_key => [:disbursed_by_staff_id],   :model => 'StaffMember'
  belongs_to :written_off_by, :child_key => [:written_off_by_staff_id], :model => 'StaffMember'
  belongs_to :validated_by,   :child_key => [:validated_by_staff_id],   :model => 'StaffMember'
  has n, :payments
  has n, :history, :model => 'LoanHistory'
  belongs_to :loan_product

  validates_with_method  :amount,                       :method => :amount_greater_than_zero?
  validates_with_method  :amount,                       :method => :installments_are_integers?
  validates_with_method  :interest_rate,                :method => :interest_rate_greater_than_zero?
  validates_with_method  :number_of_installments,       :method => :number_of_installments_greater_than_zero?
  validates_with_method  :applied_on,                   :method => :applied_before_appoved?
  validates_with_method  :approved_on,                  :method => :applied_before_appoved?
  validates_with_method  :applied_on,                   :method => :applied_before_rejected?
  validates_with_method  :rejected_on,                  :method => :applied_before_rejected?
  validates_with_method  :approved_on,                  :method => :approved_before_disbursed?
  validates_with_method  :disbursal_date,               :method => :approved_before_disbursed?
  validates_with_method  :disbursal_date,               :method => :disbursed_before_written_off?
  validates_with_method  :written_off_on,               :method => :disbursed_before_written_off?
  validates_with_method  :disbursal_date,               :method => :disbursed_before_validated?
  validates_with_method  :validated_on,                 :method => :disbursed_before_validated?
  validates_with_method  :approved_on,                  :method => :applied_before_scheduled_to_be_disbursed?
  validates_with_method  :scheduled_disbursal_date,     :method => :applied_before_scheduled_to_be_disbursed?
  validates_with_method  :approved_on,                  :method => :properly_approved?
  validates_with_method  :approved_by,                  :method => :properly_approved?
  validates_with_method  :rejected_on,                  :method => :properly_rejected?
  validates_with_method  :rejected_by,                  :method => :properly_rejected?
  validates_with_method  :written_off_on,               :method => :properly_written_off?
  validates_with_method  :written_off_by,               :method => :properly_written_off?
  validates_with_method  :disbursal_date,               :method => :properly_disbursed?
  validates_with_method  :disbursed_by,                 :method => :properly_disbursed?
  validates_with_method  :validated_on,                 :method => :properly_validated?
  validates_with_method  :validated_by,                 :method => :properly_validated?
  validates_with_method  :scheduled_first_payment_date, :method => :scheduled_disbursal_before_scheduled_first_payment?
  validates_with_method  :scheduled_disbursal_date,     :method => :scheduled_disbursal_before_scheduled_first_payment?
  validates_present      :client, :funding_line, :scheduled_disbursal_date, :scheduled_first_payment_date, :applied_by, :applied_on
  
  #product validations
  validates_with_method  :amount,                       :method => :is_valid_loan_product_amount
  validates_with_method  :interest_rate,                :method => :is_valid_loan_product_interest_rate
  validates_with_method  :number_of_installments,       :method => :is_valid_loan_product_number_of_installments

  
  def self.from_csv(row, headers, funding_lines)
    obj = new(:loan_product_id => LoanProduct.first(:name => row[headers[:product]]).id, :amount => row[headers[:amount]], 
              :interest_rate => row[headers[:interest_rate]], 
              :installment_frequency => row[headers[:installment_frequency]], :number_of_installments => row[headers[:number_of_installments]], 
              :scheduled_disbursal_date => Date.parse(row[headers[:scheduled_disbursal_date]]), 
              :scheduled_first_payment_date => Date.parse(row[headers[:scheduled_first_payment_date]]), 
              :applied_on => Date.parse(row[headers[:applied_on]]), :approved_on => Date.parse(row[headers[:approved_on]]), 
              :disbursal_date => Date.parse(row[headers[:disbursal_date]]), :fees => row[headers[:fees]], :fees_total => row[headers[:fees_total]],
              :disbursed_by_staff_id => StaffMember.first(:name => row[headers[:disbursed_by_staff]]).id, 
              :funding_line_id => funding_lines[row[headers[:funding_line_serial_number]]].id,
              :applied_by_staff_id => StaffMember.first(:name => row[headers[:applied_by_staff]]).id,
              :approved_by_staff_id => StaffMember.first(:name => row[headers[:approved_by_staff]]).id,
              :client_id => Client.first(:reference => row[headers[:client_reference]]).id)
    obj.history_disabled=true
    [obj.save, obj]
  end


  def is_valid_loan_product_amount; is_valid_loan_product(:amount); end
  def is_valid_loan_product_interest_rate; is_valid_loan_product(:interest_rate); end
  def is_valid_loan_product_number_of_installments; is_valid_loan_product(:number_of_installments); end

  def is_valid_loan_product(method)
    return [false, "No loan product chosen"] unless self.loan_product
    product = self.loan_product
    loan_attr    = self.send(method)
    #Checking if the loan adheres to minimum and maximums of the loan product
    {:min => :minimum, :max => :maximum}.each{|k, v|
      product_attr = product.send("#{k}_#{method}")
      product_attr = product_attr.to_f/100 if method==:interest_rate
      
      if k==:min and loan_attr and product_attr and  loan_attr < product_attr
        return [false, "#{v.to_s.capitalize} #{method.to_s.humanize} limit violated"]
      elsif k==:max and loan_attr and product_attr and  loan_attr > product_attr
        return  [false, "#{v.to_s.capitalize} #{method.to_s.humanize} limit violated"] 
      end      
    }
    #check if loan is follows the minimum discrete value for amount and interest
    if product.respond_to?("#{method}_multiple")
      product_attr = product.send("#{method}_multiple")
      loan_attr = loan_attr*100 if method==:interest_rate
      return  [false, "#{method.to_s.capitalize} should be in multiples of #{product_attr}"]  if not loan_attr.remainder(product_attr)==0
    end
    return true
  end


  # MISC FUNCTIONS
  def self.search(q)
    if /^\d+$/.match(q)
      all(:conditions => {:id => q})
    end
  end

  def clear_cache
    @payments_cache = @schedule = @history_array = @fee_schedule = nil
  end

  # this method returns the last date the loan history makes sense
  # used by +update_history+ for knowing when to stop.
  # (note: this is often a date in the future -- huh?!)   MAYBE: move this to the LoanHistory
  def last_loan_history_date
    s = get_status  # TODO: replace with case-when constuct
    return nil if s.nil?
    if s == :approved
      return scheduled_repaid_on
    elsif s == :outstanding
      return [scheduled_repaid_on, Date.today].max
    elsif s == :repaid
      last_payment_received_on = self.payments.first(:order => [:received_on.desc]).received_on
      return [scheduled_repaid_on, last_payment_received_on].max
    elsif s == :written_off
      return [scheduled_repaid_on, written_off_on].max
    end
    return nil  # i.e. when status is :applied or :rejected
  end

  def repayment_style
    :allow_both   # one of [:separated, :aggregated, :allow_both]
  end

  def interest_percentage  # code dup with the FundingLine
    return nil if interest_rate.blank?
    format("%.2f", interest_rate * 100)
  end
  def interest_percentage= (percentage)
    self.interest_rate = percentage.to_f/100
  end
  # returns the name of the funder
  def funder_name
    self.funding_line and self.funding_line.funder.name or nil
  end

  # the arithmic of shifting by the installment_frequency (especially months is tricky)
  # used by many other methods, it accepts a negative +number+
  # TODO: decide if we should make sure returned date is a payment date.
  def shift_date_by_installments(date, number, ensure_meeting_day = true)
    return date if number == 0
    case installment_frequency
      when :daily
        new_date =  date + number
      when :weekly
        new_date =  date + number * 7
      when :biweekly
        new_date = date + number * 14
      when :monthly
        new_month = date.month + number
        new_year  = date.year
        while new_month > 12
          new_year  += 1
          new_month -= 12
        end
        while new_month < 1
          new_year  -= 1
          new_month += 12
        end
        month_lengths = [nil, 31, (Time.gm(new_year, new_month).to_date.leap? ? 29 : 28), 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        new_day = (date.day > month_lengths[new_month]) ? month_lengths[new_month] : date.day
        new_date = Time.gm(new_year, new_month, new_day).to_date
      else
        raise ArgumentError.new("Strange period you got..")
    end
    if self.client and self.client.center and self.client.center.meeting_day != :none and ensure_meeting_day
      next_meeting_day = client.center.next_meeting_date_from(new_date)
      new_date = next_meeting_day unless new_date.weekday == client.center.meeting_day
      #new_date - new_date.cwday + Center.meeting_days.index(client.center.meeting_day)
    else
      new_date
    end
    new_date
  end

  def self.description
    "This is the description of the build-in master loan type. Typically you only deal with loan that are derived of this loan type."
  end
  def fields_partial; ''; end  # without reimplementation in the descendants these will render the default shizzle
  def show_partial;   ''; end

  def self.installment_frequencies
    # Loan.properties[:installment_frequency].type.flag_map.values would give us a garbled order, so:
    INSTALLMENT_FREQUENCIES
  end


  # LOAN MANIPULATION FUNCTIONS

  # this is the method used for creating payments, not directly on the Payment class
  # for +input+ it allows either a "total" amount as Fixnum or an array with
  # principal[0] and interest[1].
  def repay(input, user, received_on, received_by, defer_update = false)
    # this is the way to repay loans, _not_ directly on the Payment model
    # this to allow validations on the Payment to be implemented in (subclasses of) the Loan
    unless input.is_a? Array or input.is_a? Fixnum
      raise "the input argument of Loan#repay should be of class Fixnum or Array"
    end
    raise "cannot repay a loan that has not been saved" if new?

    principal, interest, total = 0, 0, nil
    if input.is_a? Fixnum  # in case only one amount is specified
      # interest is paid first, the rest goes in as principal
      # the payment is filed on received_on without knowing about the future
      # it could happen that payment have been made after this payment
      # here the validations on the Payment should 
      total        = input
      interest_due = [(-interest_overpaid_on(received_on)), 0].max
      interest     = [interest_due, total].min  # never more than total
      principal    = total - interest
    elsif input.is_a? Array  # in case principal and interest are specified separately
      principal, interest = input[0].to_i, input[1].to_i
    end
    prin_payment = Payment.new(:loan => self, :created_by => user,
      :received_on => received_on, :received_by => received_by,
      :amount => principal.round, :type => :principal)
    int_payment = Payment.new(:loan => self, :created_by => user,
      :received_on => received_on, :received_by => received_by,
      :amount => interest.round, :type => :interest)
    save_status = (prin_payment.save and int_payment.save)
    if save_status == true
      if defer_update #i.e. bulk updating loans
        Merb.run_later do
          update_history
        end
      else
        update_history  # update the history if we saved a payment
      end
      clear_cache
    end
    #payment.principal, payment.interest = nil, nil unless total.nil?  # remove calculated pr./int. values from the form
    # Merb.logger.info "loan #{id}: #{received_on} => paid #{principal} + #{interest} | prin_paid #{principal_received_up_to(received_on)} | os_bal:#{actual_outstanding_principal_on(received_on)}"
    [save_status, prin_payment, int_payment]  # return the success boolean and the payment object itself for further processing
  end

  # the way to delete payments from the db
  def delete_payment(payment, user)
    return false unless payment.loan.id == self.id
    if payment.update_attributes(:deleted_at => Time.now, :deleted_by_user_id => user.id)
      update_history
      clear_cache
      return true
    end
    p payment.errors
    false
  end

  # LOAN INFO FUNCTIONS - CALCULATIONS

  def fees_due
    fd = 0; loan_product.fees.each { |f| fd += f.fees_for(self)};
    fd
  end

  def fees_paid
    payments(:type => :fees).sum(:amount) || 0
  end

  def fees_paid?
    fees_paid >= fees_due
  end
  
  def fee_schedule
    @fee_schedule = {}
    loan_product.fees.each do |f|
      date = eval(f.payable_on.to_s)
      @fee_schedule[date] = f.fees_for(self)
    end
    @fee_schedule
  end

  def fee_payments
    @fees_payments = {}
    payments(:type => :fees, :order => :received_on).each do |p|
      @fees_payments[p.received_on] = p.amount
    end
  end

  def payment_schedule
    return @schedule if @schedule
    @schedule = {}
    principal_so_far, interest_so_far, total = 0, 0
    balance = amount
    @schedule[disbursal_date || scheduled_disbursal_date] = {:principal => 0, :interest => 0, :total_principal => 0, :total_interest => 0,
      :balance => balance, :total => 0}
    (1..number_of_installments).each do |number|
      date      = shift_date_by_installments(scheduled_first_payment_date, number - 1)
      principal = scheduled_principal_for_installment(number)
      interest  = scheduled_interest_for_installment(number)
      principal_so_far += principal
      interest_so_far  += interest
      balance -= principal
      @schedule[date] = {
        :principal                  => principal,
        :interest                   => interest,
        :total_principal            => (principal_so_far),
        :total_interest             => (interest_so_far),
        :total                      => principal_so_far + interest_so_far,
        :balance                    => balance, 
      }
    end
    # we have to do the following to avoid the circular reference from total_to_be_received.
    total = @schedule[@schedule.keys.max][:total]
    @schedule.each { |k,v| v[:total_balance] = total - v[:total]}
    @schedule
  end

  def payments_hash
    return @payments_cache if @payments_cache
    sql = %Q{
        SELECT SUM(amount * IF(type=1,1,0)) AS principal, 
               SUM(amount * IF(type=2,1,0)) AS interest,
               received_on 
        FROM payments 
        WHERE (deleted_at IS NULL) AND (loan_id = #{self.id})
        GROUP BY received_on}
    structs = id ? repository.adapter.query(sql) : []
    @payments_cache = {}
    total_balance = total_to_be_received
    @payments_cache[disbursal_date || scheduled_disbursal_date] = {
      :principal => 0, :interest => 0, :total_principal => 0, :total_interest => 0, :total => 0, :balance => amount, :total_balance => total_balance
    }
    principal, interest, total = 0, 0, 0
    structs.each do |payment|
      # we know the received_on dates are in ascending order as we
      # walk through (so we can do the += thingy)
      
      @payments_cache[payment.received_on] = {
        :principal                 => payment.principal.to_i,
        :interest                  => payment.interest.to_i,
        :total_principal           => (principal += payment.principal.to_i),
        :total_interest            => (interest  += payment.interest.to_i),
        :total                     => (total     +=payment.principal.to_i + payment.interest.to_i),
        :balance                   => amount - principal,
        :total_balance             => total_balance - total}
    end
    dates = (installment_dates + payment_dates)
    dates = dates.uniq.sort.reject{|d| d <= structs[-1].received_on} unless structs.blank?
    dates.each do |date| 
      @payments_cache[date] = {:principal => 0, :interest => 0, :total_principal => principal, :total_interest => interest, :total => total, :balance => amount - principal, :total_balance => total_balance - total}
    end
    @payments_cache
  end


  # TODO these should logically be private. 
  def get_from_cache(cache, column, date)
    date = Date.parse(date) if date.is_a? String
    return 0 if cache.blank?
    if cache.has_key?(date)
      return (column == :all ? cache[date] : cache[date][column])
    else
      return 0 if (column == :principal or column == :interest)
      keys = cache.keys.sort
      if date < keys.min
        rv = (column == :all ? cache[keys.min] : cache[keys.min][column]) 
      elsif date >= keys.max
        rv = (column == :all ? cache[keys.max] : cache[keys.max][column])
      else
        keys.each_with_index do |k,i| 
          if keys[[i+1,keys.size - 1].min] > date
            rv = (column == :all ? cache[k] : cache[k][column]) 
            break
          end
        end
      end
      if rv.is_a? Hash
        rv[:principal] = 0; rv[:interest] = 0
      end
      rv
    end
  end

  def get_scheduled(column, date) # helper function for readable functions below. make private
    payment_schedule if @schedule.nil?
    get_from_cache(payment_schedule, column, date)
  end

  def get_actual(column, date)
    payments_hash if @payments_cache.nil?
    get_from_cache(payments_hash, column, date)
  end

  # LOAN INFO FUNCTIONS - SCHEDULED

  # these 2 methods define the pay back scheme
  # These are ONE BASED
  # typically reimplemented in subclasses
  def scheduled_principal_for_installment(number)
    # number unused in this implentation, subclasses may decide differently
    # therefor always supply number, so it works for all implementations
    raise "number out of range, got #{number}" if number < 1 or number > number_of_installments
    amount.to_f / number_of_installments
  end
  def scheduled_interest_for_installment(number)  # typically reimplemented in subclasses
    # number unused in this implentation, subclasses may decide differently
    # therefor always supply number, so it works for all implementations
    raise "number out of range, got #{number}" if number < 1 or number > number_of_installments
    (amount * interest_rate / number_of_installments).to_i
  end

  # These info functions need not be overridden in derived classes.
  # We attmept to achieve speed by caching values for the duration of a request through a payment_schedule function
  # Later we write functions for
  #    scheduled_[principal, interest, total]_to_be_received
  #    scheduled_[principal, interest, total]_up_to(date)
  #    scheduled_[principal, interest, total]_on(date)



  def total_principal_to_be_received; get_scheduled(:total_principal, self.scheduled_maturity_date).to_i; end
  def total_interest_to_be_received; get_scheduled(:total_interest, self.scheduled_maturity_date).to_i; end
  def total_to_be_received; total_principal_to_be_received.to_i + total_interest_to_be_received.to_i; end

  def scheduled_principal_up_to(date); get_scheduled(:total_principal, date).to_i; end 
  def scheduled_interest_up_to(date);  get_scheduled(:total_interest,  date).to_i; end
  def scheduled_total_up_to(date); scheduled_principal_up_to(date).to_i + scheduled_interest_up_to(date).to_i;  end


  def scheduled_principal_due_on(date); get_scheduled(:principal, date).to_i; end
  def scheduled_interest_due_on(date); get_scheduled(:interest, date).to_i; end
  def scheduled_total_due_on(date); scheduled_principal_due_on(dqte) + scheduled_interest_due_on(date); end
  # these 3 methods return scheduled amounts from a LOAN-OUTSTANDING perspective
  # they are purely calculated -- no calls to its payments or loan_history)
  def scheduled_outstanding_principal_on(date)  # typically reimplemented in subclasses
    return 0 if date < applied_on
    return amount if  date < (disbursal_date || scheduled_disbursal_date)
    amount - scheduled_principal_up_to(date)
  end
  def scheduled_outstanding_interest_on(date)  # typically reimplemented in subclasses
    return 0 if date < applied_on
    return total_interest_to_be_received if date < (disbursal_date || scheduled_disbursal_date)
    total_interest_to_be_received - scheduled_interest_up_to(date)
  end
  def scheduled_outstanding_total_on(date)
    return 0 if date < applied_on
    return total_to_be_received if date < (disbursal_date || scheduled_disbursal_date)
    total_to_be_received - scheduled_total_up_to(date)
  end
  # the number of payment dates before 'date' (if date is a payment 'date' it is counted in)
  # used to calculate the outstanding value, and in the views
  def number_of_installments_before(date)
    return 0 if date < scheduled_first_payment_date
    result = case installment_frequency
      when  :daily
      then  (date - scheduled_first_payment_date).to_f.floor + 1
      when  :weekly
      then  ((date - scheduled_first_payment_date).to_f / 7).floor + 1
      when  :biweekly
      then  ((date - scheduled_first_payment_date).to_f / 14).floor + 1
      when  :monthly
      then  count = 1
            count += 1 while shift_date_by_installments(date, -count) >= scheduled_first_payment_date
            count
      else
        raise ArgumentError.new("Strange period you got..")
    end
    [result, number_of_installments].min  # never return more than the number_of_installments
  end
  

  # LOAN INFO FUNCTIONS - ACTUALS
  # the following methods basically count the payments (PAYMENT-RECEIVED perspective)
  # the last method makes the actual (optimized) db call and is cached

  def principal_received_up_to(date); get_actual(:total_principal, date); end
  def interest_received_up_to(date); get_actual(:total_interest, date); end
  def total_received_up_to(date); get_actual(:total,date); end

  def principal_received_on(date); get_actual(:principal, date); end
  def interest_received_on(date); get_actual(:interest, date); end
  def total_received_on(date); principal_received_on(date) + interest_received_on(date); end

  # these 3 methods return overpayment amounts (PAYMENT-RECEIVED perspective)
  # negative values mean shortfall (we're positive-minded at intellecap)
  def principal_overpaid_on(date)
    (principal_received_up_to(date) - scheduled_principal_up_to(date)).to_i
  end
  def interest_overpaid_on(date)
    (interest_received_up_to(date) - scheduled_interest_up_to(date)).to_i
  end
  def total_overpaid_on(date)
    total_received_up_to(date) - scheduled_total_up_to(date)
  end
  # these 3 methods return actual outstanding amounts (LOAN-OUTSTANDING perspective)
  def actual_outstanding_principal_on(date)
    get_actual(:balance, date)
  end
  def actual_outstanding_interest_on(date)
    scheduled_outstanding_interest_on(date) - interest_overpaid_on(date)
  end
  def actual_outstanding_total_on(date)
    scheduled_outstanding_total_on(date) - total_overpaid_on(date)
  end
  def payment_dates
    payments.map { |p| p.received_on }
  end


  def status(date = Date.today)
    get_status(date)
  end

  def get_status(date = Date.today, total_received = nil) # we have this last parameter so we can speed up get_status
                                                          # considerably by passing total_received, i.e. from history_for
    #return @status if @status
    date = Date.parse(date)      if date.is_a? String
    return :applied_in_future    if applied_on > date  # non existant
    return :pending_approval     if applied_on <= date and
                                 not (approved_on and approved_on <= date) and
                                 not (rejected_on and rejected_on <= date)
    return :approved             if (approved_on and approved_on <= date) and not (disbursal_date and disbursal_date <= date)
    return :rejected             if (rejected_on and rejected_on <= date)
    return :written_off          if (written_off_on and written_off_on <= date)
    total_received ||= total_received_up_to(date)
    return :disbursed          if (date == disbursal_date) and total_received < total_to_be_received
    @status = total_received  >= total_to_be_received ? :repaid : :outstanding
  end


  # LOAN INFO FUNCTIONS - DATES
  def date_for_installment(number)
    shift_date_by_installments(scheduled_first_payment_date, number-1)
  end
  def scheduled_maturity_date
    shift_date_by_installments(scheduled_first_payment_date, number_of_installments - 1)
  end
  def scheduled_repaid_on
    # first payment is on "scheduled_first_payment_date", so number_of_installments-1 periods later
    # we find the scheduled_repaid_on date.
    shift_date_by_installments(scheduled_first_payment_date, number_of_installments - 1)
  end
  # the installment dates
  def installment_dates
    (0..(number_of_installments-1)).to_a.map { |x| shift_date_by_installments(scheduled_first_payment_date, x) }
  end

  # HISTORY

  # Moved this method here from instead of the LoanHistory model for purposes of speed. We sacrifice a bit of readability
  # for brute force iterations and caching => speed

  def update_history
    return if history_disabled  # easy when doing mass db modifications (like with fixutes)
    clear_cache
    update_history_bulk_insert
  end

  def calculate_history
    return @history_array if @history_array
    t = Time.now
    current = nil
    @history_array = []
    dates = ([applied_on, approved_on, scheduled_disbursal_date, disbursal_date, written_off_on,scheduled_first_payment_date] + payment_dates + installment_dates).compact.uniq.sort
    last_paid_date = nil
    dates.each_with_index do |date,i|
      current = ((dates[[i-1,0].max] < Date.today and dates[[dates.size - 1,i+1].min] > Date.today) or (i == dates.size - 1 and dates[i] < Date.today)) ? 1 : 0
      scheduled = get_scheduled(:all, date)
      actual = get_actual(:all, date)
      # puts "#{i} #{date} #{scheduled[:balance]} #{actual[:balance]} :: #{scheduled[:principal]} #{actual[:principal]}"
      scheduled_outstanding_principal = scheduled[:balance]
      scheduled_outstanding_total = scheduled[:total_balance]
      actual_outstanding_principal = actual[:balance]
      actual_outstanding_total = actual[:total_balance]
      total_due = actual_outstanding_total - scheduled_outstanding_total
      principal_due = actual_outstanding_principal - scheduled_outstanding_principal
      interest_due = actual_outstanding_total - scheduled_outstanding_total - principal_due
      prin = principal_received_on(date)
      int = interest_received_on(date)
      default = (principal_due + interest_due > prin + int) and date >= scheduled_first_payment_date
      if default
        last_paid_date ||= dates[[i,dates.size-1].min] 
        days_overdue = [0,date - last_paid_date].max
      else
        last_paid_date = nil
        days_overdue = 0
      end
      @history_array << {:loan_id => id, :date => date, 
                           :status => STATUSES.index(get_status(date)) + 1, 
                           :scheduled_outstanding_principal => scheduled_outstanding_principal,
                           :scheduled_outstanding_total => scheduled_outstanding_total,
                           :actual_outstanding_principal => actual_outstanding_principal,
                           :actual_outstanding_total => actual_outstanding_total,
                           :amount_in_default => [0,scheduled_outstanding_principal - actual_outstanding_principal].max,
                           :days_overdue => days_overdue, :current => current || 0,
                           :principal_due => principal_due, :interest_due => interest_due,
                           :principal_paid => prin, :interest_paid => int}
    end
    Merb.logger.info "History calculation took #{Time.now - t} seconds"
    @history_array
  end

  def update_history_bulk_insert
    t = Time.now
    Merb.logger.error! "could not destroy the history" unless self.history.destroy!
    d0 = Date.parse('2000-01-03')
    sql = %Q{ INSERT INTO loan_history(loan_id, date, status, 
              scheduled_outstanding_principal, scheduled_outstanding_total,
              actual_outstanding_principal, actual_outstanding_total, current, amount_in_default,
              center_id, client_id, branch_id, days_overdue, week_id, principal_due, interest_due, principal_paid, interest_paid)
              VALUES }
    values = []
    calculate_history.each do |history|
      value = %Q{(#{id}, '#{history[:date]}', #{history[:status]}, #{history[:scheduled_outstanding_principal]}, 
                          #{history[:scheduled_outstanding_total]}, #{history[:actual_outstanding_principal]},
                          #{history[:actual_outstanding_total]},#{history[:current]},
                          #{history[:amount_in_default]}, #{client.center.id},#{client.id},#{client.center.branch.id},
                          #{history[:days_overdue]}, #{((history[:date] - d0) / 7).to_i + 1}, 
                          #{history[:principal_due]},#{history[:interest_due]},
                          #{history[:principal_paid]},#{history[:interest_paid]})}


     values << value
    end
    sql += values.join(",") + ";"
    repository.adapter.execute(sql)
    Merb.logger.info "update_history_bulk_insert done in #{Time.now - t}"
  end

  private
  include DateParser  # mixin for the hook "before :valid?, :parse_dates"
  include Misfit::LoanValidators
  ## validations: read their method name and error to see what they do.
  def amount_greater_than_zero?
    return true if not amount.blank? and amount > 0
    [false, "Loan amount should be greater than zero"]
  end
  def interest_rate_greater_than_zero?
    return true if interest_rate and interest_rate.to_f > 0
    [false, "Interest rate should be greater than zero"]
  end
  def number_of_installments_greater_than_zero?
    return true if number_of_installments and number_of_installments.to_i > 0
    [false, "Number of installments should be greater than zero"]
  end
  def applied_before_appoved?
    return true if approved_on.blank? or (approved_on and applied_on and approved_on >= applied_on)
    [false, "Cannot be approved before it is applied for"]
  end
  def applied_before_rejected?
    return true if rejected_on.blank? or (rejected_on and applied_on and rejected_on >= applied_on)
    [false, "Cannot be rejected before it is applied for"]
  end
  def approved_before_disbursed?
    return true if disbursal_date.blank? or (disbursal_date and approved_on and disbursal_date >= approved_on)
    [false, "Cannot be disbursed before it is approved"]
  end
  def disbursed_before_validated?
    return true if validated_on.blank? or (disbursal_date and validated_on and disbursal_date <= validated_on)
    [false, "Cannot be validated before it is disbursed"]
  end
  def disbursed_before_written_off?
    return true if written_off_on.blank? or (disbursal_date and written_off_on and disbursal_date <= written_off_on)
    [false, "Cannot be written off before it is disbursed"]
  end
  def applied_before_scheduled_to_be_disbursed?
    return true if scheduled_disbursal_date and applied_on and scheduled_disbursal_date >= applied_on
    [false, "Cannot be scheduled for disbusal before it is applied"]
  end
  def scheduled_disbursal_before_scheduled_first_payment?
    return true if scheduled_disbursal_date and scheduled_first_payment_date and scheduled_disbursal_date <= scheduled_first_payment_date
    [false, "The scheduled first payment date cannot precede the scheduled disbursal date"]
  end
  def properly_approved?
    return true if (approved_on and approved_by) or (approved_on.blank? and approved_by.blank?)
    [false, "The approval date and the staff member that approved the loan should both be given"]
  end
  def properly_rejected?
    return true if (rejected_on and rejected_by) or (rejected_on.blank? and rejected_by.blank?)
    [false, "The rejection date and the staff member that rejected the loan should both be given"]
  end
  def properly_written_off?
    return true if (written_off_on and written_off_by) or (written_off_on.blank? and written_off_by.blank?)
    [false, "The date of writing off the loan and the staff member that wrote off the loan should both be given"]
  end
  def properly_disbursed?
    return true if (disbursal_date and disbursed_by) or (disbursal_date.blank? and disbursed_by.blank?)
    [false, "The disbursal date and the staff member that disbursed the loan should both be given"]
  end
  def properly_validated?
    # if the validation_comment is not blank we also invalidate the model
    return true if (validated_on and validated_by) or (validated_on.blank? and validated_by.blank? and validation_comment.blank?)
    [false, "The validation date, the validating staff member the loan should both be given"]
  end
end

class DefaultLoan < Loan
  # This is the "Default" loan type. It is nothing better of worse than its parent.
  # That explains the emptyness
  def self.description
    "This is the default loan in Mostfit. In this loan type interest is is paid flat over the installments, so all the installments are the same size. It allows both repayment in totals and repayment in principal-interest pairs. In case of paying in totals the interest due is payed before the principal due."
  end
  def fields_partial
    ''  # this method is are used plug HTML into the show page of the loan and its payments (app/views/payments/index.html.haml)
  end
  def show_partial
    ''  # this method is are used plug HTML into the show page of the loan and its payments (app/views/payments/index.html.haml)
  end
end

class A50Loan < Loan
  # a fine example of a subclassing (if it was finished)
  # these 2 methods define the pay back scheme
  # typically reimplemented in subclasses
  property :purpose,  String

  attr_accessor :defaults

  def defaults
    {:interest_rate => 0.18, :installment_frequency => :weekly, :number_of_installments => 50}
  end

  def self.description
    "50 Weeks, 18%, [6000-10000]"
  end

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
    number < 45 ? total_interest_to_be_received / 45 : 0
  end
end

class EquatedWeekly < Loan
  # these 2 methods define the pay back scheme
  # typically reimplemented in subclasses
  include ExcelFormula
  property :purpose,  String
  
  attr_accessor :defaults

  def defaults
    {:interest_rate => 0.18, :installment_frequency => :weekly, :number_of_installments => 50}
  end

  def self.description
    "50 Weeks, 18%, [6000-10000]"
  end

  def scheduled_principal_for_installment(number)
    # number unused in this implentation, subclasses may decide differently
    # therefor always supply number, so it works for all implementations
    raise "number out of range, got #{number} but max is #{number_of_installments}" if number < 0 or number > number_of_installments
    payment             = pmt(interest_rate/number_of_installments, number_of_installments, amount, 0, 0)
    principal_payable   = 0
    balance             = amount

    1.upto(number){|installment|
      interest_payable  = balance * interest_rate / number_of_installments
      principal_payable = payment - interest_payable
      balance           = balance - principal_payable
    }
    return number==number_of_installments ? balance.ceil : principal_payable.to_i
  end

  def scheduled_interest_for_installment(number)  # typically reimplemented in subclasses
    # number unused in this implentation, subclasses may decide differently
    # therefor always supply number, so it works for all implementations
    raise "number out of range, got #{number}" if number < 0 or number > number_of_installments
    payment             = pmt(interest_rate/number_of_installments, number_of_installments, amount, 0, 0)
    interest_payable    = 0
    balance             = amount
    
    1.upto(number){|installment|
      interest_payable  = balance * interest_rate / number_of_installments
      principal_payable = payment - interest_payable
      balance           = balance - principal_payable
    }
    return interest_payable.to_i
  end
end


