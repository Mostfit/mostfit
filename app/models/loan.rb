class Loan
  include DataMapper::Resource
  before :valid?,  :parse_dates
  after  :save,    :update_history  # also seems to do updates
  after  :destroy, :update_history

  INSTALLMENT_FREQUENCIES = [:daily, :weekly, :biweekly, :monthly]
  STATUSES = [:applied_in_future, :pending_approval, :rejected, :approved, :outstanding, :repaid, :written_off]
#   DATE_FORMAT = /(^\s*$|\d{4}[-.\/]{1}\d{1,2}[-.\/]{1}\d{1,2})/  # matches "1982-06-12" or empty strings

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
  property :fees,                           Yaml  # like: "first fee: 1000, second fee: 200" (yaml) -- fully reimplementable

  property :fees_total,                     Integer, :default => 0, :index => true  # gets included in first payment
  property :fees_paid,                      Boolean, :default => false, :index => true
  property :validated_on,                   Date, :auto_validation => false, :index => true

  property :validation_comment,             Text
  property :created_at,                     DateTime, :index => true
  property :updated_at,                     DateTime, :index => true

  # associations
  belongs_to :client
  belongs_to :funding_line
  belongs_to :applied_by,     :child_key => [:applied_by_staff_id],     :class_name => 'StaffMember', :index => true
  belongs_to :approved_by,    :child_key => [:approved_by_staff_id],    :class_name => 'StaffMember', :index => true
  belongs_to :rejected_by,    :child_key => [:rejected_by_staff_id],    :class_name => 'StaffMember', :index => true
  belongs_to :disbursed_by,   :child_key => [:disbursed_by_staff_id],   :class_name => 'StaffMember', :index => true
  belongs_to :written_off_by, :child_key => [:written_off_by_staff_id], :class_name => 'StaffMember', :index => true
  belongs_to :validated_by,   :child_key => [:validated_by_staff_id],   :class_name => 'StaffMember', :index => true
  has n, :payments
  has n, :history, :class_name => 'LoanHistory'


  validates_with_method  :amount,                       :method => :amount_greater_than_zero?
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


  def self.search(q)
    if /^\d+$/.match(q)
      all(:conditions => {:id => q})
    end
  end

  def defaults
    # this method should be overwritten by derived classes to provide default values
    {}
  end


  def required
    # this method provides required values. i.e. 50 weeks only
    {}
  end
  # validates_primitive doesn't work well for date -- we use "before :valid?, :parse_dates" to achieve similar effects 

  # this is the method used for creating payments, not directly on the Payment class
  # for +input+ it allows either a "total" amount as Fixnum or an array with
  # principal[0] and interest[1].
  def repay(input, user, received_on, received_by, defer_update = false)
    # this is the way to repay loans, _not_ directly on the Payment model
    # this to allow validations on the Payment to be implemented in (subclasses of) the Loan
    unless input.is_a? Array or input.is_a? Fixnum
      raise "the input argument of Loan#repay should be of class Fixnum or Array"
    end
    raise "cannot repay a loan that has not been saved" if new_record?

    principal, interest, total = 0, 0, nil
    if input.is_a? Fixnum  # in case only one amount is specified
      # interest is paid first, the rest goes in as principal
      # the payment is filed on received_on without knowing about the future
      # it could happen that payment have been made after this payment
      # here the validations on the Payment should 
      total        = input
      interest_due = [(-interest_overpaid_on(received_on)).round, 0].max
      interest     = [interest_due, total].min  # never more than total
      principal    = total - interest
    elsif input.is_a? Array  # in case principal and interest are specified separately
      principal, interest = input[0].to_i, input[1].to_i
    end
    payment = Payment.new(:loan => self, :created_by => user,
      :received_on => received_on, :received_by => received_by,
      :principal => principal.round, :interest => interest.round)
    save_status = payment.save
    if save_status == true
      if defer_update #i.e. bulk updating loans
        Merb.run_later do
          update_history
        end
      else
        update_history  # update the history if we saved a payment
      end
      clear_payments_hash_cache
    end
    payment.principal, payment.interest = nil, nil unless total.nil?  # remove calculated pr./int. values from the form
    Merb.logger.info "loan #{id}: #{received_on} => paid #{principal} + #{interest} | prin_paid #{principal_received_up_to(received_on)} | os_bal:#{actual_outstanding_principal_on(received_on)}"
    [save_status, payment]  # return the success boolean and the payment object itself for further processing
  end

  # the way to delete payments from the db
  def delete_payment(payment, user)
    return false unless payment.loan.id == self.id
    if payment.update_attributes(:deleted_at => Time.now, :deleted_by_user_id => user.id)
      update_history
      clear_payments_hash_cache
      return true
    end
    p payment.errors
    false
  end


  # these 2 methods define the pay back scheme
  # These are ZERO BASED
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
    (total_interest_to_be_received / number_of_installments)
  end
  def date_for_installment(number)
    shift_date_by_installments(scheduled_first_payment_date, number)
  end
  def scheduled_maturity_date
    shift_date_by_installments(scheduled_first_payment_date, number_of_installments - 1)
  end

  # the 'grande totale' of what the client has to pay back for this loan
  # used in many places
  def total_to_be_received
    self.amount + total_interest_to_be_received
  end
  def total_interest_to_be_received
    ((self.amount * self.interest_rate) / number_of_installments).round * number_of_installments
  end

  # the following methods basically count the payments (PAYMENT-RECEIVED perspective)
  # the last method makes the actual (optimized) db call and is cached
  def principal_received_up_to(date)
    payments_received_up_to(date)[:principal_received_so_far]
#    payments(:received_on.lte => date).sum(:principal)
  end
  def interest_received_up_to(date)
    payments_received_up_to(date)[:interest_received_so_far]
  end
  def total_received_up_to(date)
    payments_received_up_to(date)[:total_received_so_far]
  end  
  # private??
  # returns an array with as contents sums of the principal[0], interest[1] and total[2]
  # proper optimization, and good example of falling back to SQL and query-caching
  def payments_received_up_to(date)
    date = Date.parse(date) if date.is_a? String

    # pick the latestest key<Date> of the payments_hash that is not greater than +date+
    d = Date.new(0)
    payments_hash.keys.each { |n| (d = n if (n > d and n <= date)) if n }
    return payments_hash[d] if (not d == Date.new(0)) and payments_hash[d]
    {:principal_received_so_far => 0, :interest_received_so_far => 0, :total_received_so_far => 0}
  end


  # probably this is the best caching trick ever..
  # payments will rarely be over a hundred, and even that is (one read query) blazing fast.
  # so best is not to recalculate everytime, or query all along -- but to cache.
  def payments_hash

    return @payments_hash_cache if @payments_hash_cache
#    payments = Payment.all(:loan_id => self.id, :order => [:received_on.asc])
    structs = repository.adapter.query(%Q{
      SELECT principal, interest, received_on
        FROM payments
       WHERE (deleted_at IS NULL) AND (loan_id = #{self.id})
    ORDER BY received_on})
    @payments_hash_cache = {}
    principal, interest, total = 0, 0, 0
    structs.each do |payment|
      # we know the received_on dates are in ascending order as we
      # walk through (so we can do the += thingy)
      @payments_hash_cache[payment.received_on] = {
        :principal_received_so_far => (principal += payment.principal),
        :interest_received_so_far =>  (interest  += payment.interest),
        :total_received_so_far =>     (total     +=payment.principal + payment.interest) }
    end
    @payments_hash_cache
  end

  def clear_payments_hash_cache
    @payments_hash_cache = nil
  end

  # these 3 methods return scheduled amounts from a PAYMENT-RECEIVED perspective
  # they work by looping over scheduled_principal_for_installment and scheduled_interest_for_installment
  # you should not have to re-implement them in the subclasses
  def scheduled_received_principal_up_to(date) 
    amount = 0
    (0..number_of_installments_before(date)-1).each do |i|
      amount += scheduled_principal_for_installment(i)
    end
    amount
  end
  def scheduled_received_interest_up_to(date)
    amount = 0
    (0..number_of_installments_before(date)-1).each do |i|
      amount += scheduled_interest_for_installment(i)
    end
    amount
  end
  def scheduled_received_total_up_to(date)
    scheduled_received_principal_up_to(date) + scheduled_received_interest_up_to(date)
  end

  # these 3 methods return scheduled amounts from a LOAN-OUTSTANDING perspective
  # they are purely calculated -- no calls to its payments or loan_history)
  def scheduled_outstanding_principal_on(date)  # typically reimplemented in subclasses
    return 0 if not disbursal_date or date < disbursal_date
    amount - scheduled_received_principal_up_to(date)
  end
  def scheduled_outstanding_interest_on(date)  # typically reimplemented in subclasses
    return 0 if not disbursal_date or date < disbursal_date
    total_interest_to_be_received - scheduled_received_interest_up_to(date)
  end
  def scheduled_outstanding_total_on(date)
    return 0 if not disbursal_date or date < disbursal_date
    total_to_be_received - scheduled_received_total_up_to(date)
  end

    


  # these 3 methods return overpayment amounts (PAYMENT-RECEIVED perspective)
  # negative values mean shortfall (we're positive-minded at intellecap)
  def principal_overpaid_on(date)
    principal_received_up_to(date) - scheduled_received_principal_up_to(date)
  end
  def interest_overpaid_on(date)
    interest_received_up_to(date) - scheduled_received_interest_up_to(date)
  end
  def total_overpaid_on(date)
    total_received_up_to(date) - scheduled_received_total_up_to(date)
  end

  # these 3 methods return actual outstanding amounts (LOAN-OUTSTANDING perspective)
  def actual_outstanding_principal_on(date)
    scheduled_outstanding_principal_on(date) - principal_overpaid_on(date)
  end
  def actual_outstanding_interest_on(date)
    scheduled_outstanding_interest_on(date) - interest_overpaid_on(date)
  end
  def actual_outstanding_total_on(date)
    scheduled_outstanding_total_on(date) - total_overpaid_on(date)
  end


  # used by the views to quickly get an overview of the "calculated schedule"
  # to compose this schedule one query for each installment is made
  def payment_schedule
    schedule = []
    principal_so_far, interest_so_far = 0, 0
    scheduled_balance, actual_balance = amount, amount
    schedule << {
      :date => disbursal_date || scheduled_disbursal_date, :principal => 0, :interest => 0, :principal_so_far => 0, :interest_so_far => 0,
      :principal_received_so_far => 0, :interest_received_so_far => 0, :principal_overpaid => 0, 
      :interest_overpaid => 0, :scheduled_balance => scheduled_balance, :actual_balance => actual_balance
    }
    number_of_installments.times do |number|
      date      = shift_date_by_installments(scheduled_first_payment_date, number)
      principal = scheduled_principal_for_installment(number)
      interest  = scheduled_interest_for_installment(number)
      principal_so_far += principal
      interest_so_far  += interest
      scheduled_balance -= principal
      actual_balance = amount - principal_so_far
      schedule << {
        :date                       => date,
        :principal                  => principal,
        :interest                   => interest,
        :principal_so_far           => (principal_so_far),
        :interest_so_far            => (interest_so_far),
        :principal_received_so_far  => principal_received_up_to(date),
        :interest_received_so_far   => interest_received_up_to(date),
        :principal_overpaid         => principal_overpaid_on(date),
        :interest_overpaid          => interest_overpaid_on(date),
        :scheduled_balance          => scheduled_balance, 
        :actual_balance             => actual_balance
      }
    end
    schedule
  end

  # the installment dates
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
    :allow_both   # one of [:separated, :aggregated, :allow_both]
  end

  def interest_percentage  # code dup with the FundingLine
    return nil if interest_rate.blank?
    format("%.2f", interest_rate * 100)
  end
  def interest_percentage= (percentage)
    self.interest_rate = percentage.to_f/100
  end

  # this method returns one of [nil, :approved, :outstanding, :repaid, :written_off]

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
    total_received = total_received.nil? ? total_received_up_to(date) : total_received
    return :outstanding          if (date == disbursal_date) and total_received < total_to_be_received
    @status = total_received  >= total_to_be_received ? :repaid : :outstanding
  end
  
  def update_status # DEPRECATED? check if this is actually being called. I think we moved this to loan_history with
                    # a 'current' flag.
    self.status = history[:status]
    if not payments.empty?
      self.last_payment_received_on = payments.all(:order => [:received_on.desc]).first.received_on
    end
    self.amount_in_default = history[:actual_outstanding_principal] - history[:scheduled_outstanding_principal]
    self.history_disabled = true
    Merb.logger.notice! "Saving loan #{id}"
    self.save
  end

  def scheduled_repaid_on
    # first payment is on "scheduled_first_payment_date", so number_of_installments-1 periods later
    # we find the scheduled_repaid_on date.
    shift_date_by_installments(scheduled_first_payment_date, number_of_installments - 1)
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
  

  # Moved this method here from instead of the LoanHistory model for purposes of speed. We sacrifice a bit of readability
  # for brute force iterations and caching => speed

  def history_for(date)
    t0 = Time.now
    scheduled_os_principal = amount
    scheduled_os_total = total_to_be_received
    t0 = Time.now
    i_number = number_of_installments_before(date)-1
    Merb.logger.debug "history: #{date}:#{i_number}. history array = #{@history_array.inspect}"

    last_payment_date = nil
    payments_hash.keys.sort.each do |k|
      last_payment_date = k unless k > date
    end
    days_overdue = last_payment_date.nil? ? 0 : (date - last_payment_date)
    if @history_array.nil? #like @payments_hash, we cache @history_array to avoid repeated calls to the database
      0.upto(i_number) do |i|
        prin = scheduled_principal_for_installment(i)
        int = scheduled_interest_for_installment(i)
        scheduled_os_principal -= prin
        scheduled_os_total -= (int + prin)
      end
      prin = date == disbursal_date ? 0 : principal_received_up_to(date)
      int = date == disbursal_date ? 0 : interest_received_up_to(date)
      actual_os_principal = amount - prin
      actual_os_total = total_to_be_received - int -prin
      st = STATUSES.index(get_status(date, total_to_be_received - actual_os_total))
      @history_array = {:loan_id => id, :date => date, :status => st, :scheduled_outstanding_principal => scheduled_os_principal, :scheduled_outstanding_total => scheduled_os_total, :actual_outstanding_principal => actual_os_principal, :actual_outstanding_total => actual_os_total, :days_overdue => days_overdue, :principal_paid => 0, :interest_paid => 0}
    else
      prin = i_number < 0 ? 0 : scheduled_principal_for_installment(i_number)
      act_prin = principal_received_up_to(date)
      int = i_number < 0 ? 0 : scheduled_interest_for_installment(i_number)
      act_int = interest_received_up_to(date)
      @history_array[:scheduled_outstanding_principal] -= prin 
      @history_array[:scheduled_outstanding_total] -= (int + prin)
      @history_array[:actual_outstanding_principal] = amount - act_prin
      @history_array[:actual_outstanding_total] = total_to_be_received - (act_prin + act_int)
      @history_array[:principal_paid] = prin
      @history_array[:interest_paid] = int
      @history_array[:status] = STATUSES.index(get_status(date, total_to_be_received - @history_array[:actual_outstanding_total]))
      @history_array[:days_overdue] = days_overdue
    end
    @history_array
  end

  def update_history
    return if history_disabled  # easy when doing mass db modifications (like with fixutes)
    @status = nil
    update_history_bulk_insert
  end

#  def update_history_now  # DEPRECATED - use update_history_bulk_insert instead
#    Merb.logger.error! "could not destroy the history" unless self.history.destroy!
#    dates = payment_dates + installment_dates
#    dates << disbursal_date if disbursal_date
#    dates << written_off_on if written_off_on
#    dates.uniq.sort.each do |date|
#      LoanHistory.write_for(self, date)
#    end
#  end

  def update_history_bulk_insert
    t = Time.now
    Merb.logger.error! "could not destroy the history" unless self.history.destroy!
    @history_array = nil
    d0 = Date.parse('2000-01-03')
    dates = [applied_on, approved_on, scheduled_disbursal_date,scheduled_first_payment_date] + payment_dates + installment_dates
    dates << disbursal_date if disbursal_date
    dates << written_off_on if written_off_on
    sql = %Q{ INSERT INTO loan_history(loan_id, date, status, 
              scheduled_outstanding_principal, scheduled_outstanding_total,
              actual_outstanding_principal, actual_outstanding_total, current, amount_in_default,
              center_id, client_id, branch_id, days_overdue, week_id, principal_paid, interest_paid)
              VALUES }
    values = []
    status_updated = false
    dates = dates.uniq.sort
    dates.each_with_index do |date,index|
      history = history_for(date)
      if (dates[[index + 1,dates.size - 1].min] > Date.today or index == dates.size - 1) and not status_updated
        current = 1
        status_updated = true
      else
        current = 0
      end
      amount_in_default = date <= Date.today ? history[:actual_outstanding_total] - history[:scheduled_outstanding_total] : 0
      value = %Q{(#{id}, '#{date}', #{history[:status]}, #{history[:scheduled_outstanding_principal]}, 
                          #{history[:scheduled_outstanding_total]}, #{history[:actual_outstanding_principal]},
                          #{history[:actual_outstanding_total]},#{current},
                          #{amount_in_default}, #{client.center.id},#{client.id},#{client.center.branch.id},
                          #{history[:days_overdue]}, #{((date - d0) / 7).to_i + 1}, #{history[:principal_paid]},#{history[:interest_paid]})}

     values << value
    end
    sql += values.join(",") + ";"
    repository.adapter.execute(sql)
    Merb.logger.info "update_history_bulk_insert done in #{Time.now - t}"
    
  end

  # FINDERS
  def self.defaulted_loan_info (days = 7, date = Date.today, query ={})
    # this does not work as expected if the loan is repaid and goes back into default within the days we are looking at it.
    # the fix is to have a days_overdue column in loan_history
    defaulted_loan_ids = repository.adapter.query(%Q{
      SELECT loan_id FROM
        (select loan_id, max(ddiff) as diff from (select date, loan_id, datediff(now(),date) as ddiff,actual_outstanding_principal - scheduled_outstanding_principal as diff from loan_history where actual_outstanding_principal != scheduled_outstanding_principal and date < now()) as dt group by loan_id having diff < #{days}) as dt1;})

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

  def interest_percentage
    return nil if interest_rate.blank?
    format("%.2f", interest_rate * 100)
  end
  def interest_percentage=(percentage)
    self.interest_rate = percentage.blank? ? nil : percentage.to_f / 100
  end

  #def interest_rate=(rate)
  #  interest_rate  = rate.to_f > 1 ? int.to_f/100 : int.to_f
  #end

#  alias :set_fees_without_updating_total :fees=
#  def fees=(fees)
#    set_fees_without_updating_total fees
#    update_fees_total
#  end

  private
  include DateParser  # mixin for the hook "before :valid?, :parse_dates"

  ## validations: read their method name and error to see what they do.
  def amount_greater_than_zero?
    return true if not amount.blank? and amount > 0
    [false, "Loan amount should be greater than zero"]
  end
  def interest_rate_greater_than_zero?
    return true if interest_rate and interest_rate > 0
    [false, "Interest rate should be greater than zero"]
  end
  def number_of_installments_greater_than_zero?
    return true if number_of_installments and number_of_installments > 0
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


  # this method only works if fees are in a format of:
  #   "fee1: 100\nfee2: 200":String (yaml)
  # and gets called from the free= method, yet all this is fully reimplementable
  def update_fees_total
    return if fees.blank?
    total = 0
    fees = YAML.load(self.fees) if self.fees.is_a? String
    fees.each_value { |v| total += v.to_i }
    self.fees_total = total
  end

  def payment_dates
    #repository.adapter.query(%Q{
    #  SELECT "received_on" FROM "payments"    -- the payment dates
    #   WHERE ("deleted_at" IS NULL) AND ("loan_id" = #{self.id})}).map { |x| Date.parse(x) }
    payments.map { |p| p.received_on }
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

