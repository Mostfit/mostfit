class Loan
  include DataMapper::Resource
  before :valid?,  :parse_dates
  after  :save,    :update_history  # also seems to do updates
  after  :destroy, :update_history

  INSTALLMENT_FREQUENCIES = [:daily, :weekly, :biweekly, :monthly]
#   DATE_FORMAT = /(^\s*$|\d{4}[-.\/]{1}\d{1,2}[-.\/]{1}\d{1,2})/  # matches "1982-06-12" or empty strings

  attr_accessor :history_disabled  # set to true to disable history writing by this object
  attr_accessor :interest_percentage  # set to true to disable history writing by this object
  
  property :id,                             Serial
  property :discriminator,                  Discriminator, :nullable => false
  property :amount,                         Integer, :nullable => false  # see helper for formatting
  property :interest_rate,                  Float, :nullable => false
  property :installment_frequency,          Enum.send('[]', *INSTALLMENT_FREQUENCIES), :nullable => false
  property :number_of_installments,         Integer, :nullable => false
  property :scheduled_disbursal_date,       Date, :nullable => false, :auto_validation => false
  property :scheduled_first_payment_date,   Date, :nullable => false, :auto_validation => false
  property :applied_on,                     Date, :nullable => false, :auto_validation => false
  property :approved_on,                    Date, :auto_validation => false
  property :rejected_on,                    Date, :auto_validation => false
  property :disbursal_date,                 Date, :auto_validation => false
  property :written_off_on,                 Date, :auto_validation => false
  property :fees,                           Yaml  # like: "first fee: 1000, second fee: 200" (yaml) -- fully reimplementable
  property :fees_total,                     Integer, :default => 0  # gets included in first payment
  property :fees_paid,                      Boolean, :default => false
  property :validated_on,                   Date, :auto_validation => false
  property :validation_comment,             Text
  property :created_at,                     DateTime
  property :updated_at,                     DateTime

  belongs_to :client
  belongs_to :funding_line
  belongs_to :applied_by,     :child_key => [:applied_by_staff_id],     :class_name => 'StaffMember'
  belongs_to :approved_by,    :child_key => [:approved_by_staff_id],    :class_name => 'StaffMember'
  belongs_to :rejected_by,    :child_key => [:rejected_by_staff_id],    :class_name => 'StaffMember'
  belongs_to :disbursed_by,   :child_key => [:disbursed_by_staff_id],   :class_name => 'StaffMember'
  belongs_to :written_off_by, :child_key => [:written_off_by_staff_id], :class_name => 'StaffMember'
  belongs_to :validated_by,   :child_key => [:validated_by_staff_id],   :class_name => 'StaffMember'
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
  # validates_primitive doesn't work well for date -- we use "before :valid?, :parse_dates" to achieve similar effects 

  # this is the method used for creating payments, not directly on the Payment class
  # for +input+ it allows either a "total" amount as Fixnum or an array with
  # principal[0] and interest[1].
  def repay(input, user, received_on, received_by)
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
      update_history  # update the history is we saved a payment
      clear_payments_hash_cache
    end
    payment.principal, payment.interest = nil, nil unless total.nil?  # remove calculated pr./int. values from the form
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
    total_interest_to_be_received / number_of_installments
  end

  # the 'grande totale' of what the client has to pay back for this loan
  # used in many places
  def total_to_be_received
    (self.amount.to_f * (1 + self.interest_rate)).round
  end
  def total_interest_to_be_received
    amount * interest_rate
  end

  # the following methods basically count the payments (PAYMENT-RECEIVED perspective)
  # the last method makes the actual (optimized) db call and is cached
  def principal_received_up_to(date)
    payments_received_up_to(date)[:principal_received_so_far]
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
    structs = repository.adapter.query(%Q{
      SELECT "principal", "interest", "received_on"  -- fill the payments_hash_cache
        FROM "payments"
       WHERE ("deleted_at" IS NULL) AND ("loan_id" = #{self.id})
    ORDER BY "received_on"})
    @payments_hash_cache = {}
    principal, interest, total = 0, 0, 0
    structs.each do |s|
      # we know the received_on dates are in ascending order as we
      # walk through (so we can do the += thingy)
      @payments_hash_cache[ Date.parse(s[:received_on]) ] = {
        :principal_received_so_far => (principal += s[:principal]),
        :interest_received_so_far =>  (interest  += s[:interest]),
        :total_received_so_far =>     (total     += s[:principal] + s[:interest]) }
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
    number_of_installments.times do |number|
      date      = shift_date_by_installments(scheduled_first_payment_date, number)
      principal = scheduled_principal_for_installment(number)
      interest  = scheduled_interest_for_installment(number)
      schedule << {
        :date                       => date,
        :principal                  => principal,
        :interest                   => interest,
        :principal_so_far           => (principal_so_far += principal),
        :interest_so_far            => (interest_so_far  += interest),
        :principal_received_so_far  => principal_received_up_to(date),
        :interest_received_so_far   => interest_received_up_to(date),
        :principal_overpaid         => principal_overpaid_on(date),
        :interest_overpaid          => interest_overpaid_on(date) }
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
    return nil          if applied_on > date  # non existant
    return :pending     if applied_on <= date and
                          not (approved_on and approved_on <= date) and
                          not (rejected_on and rejected_on <= date)
    return :approved    if (approved_on and approved_on <= date) and not (disbursal_date and disbursal_date <= date)
    return :rejected    if (rejected_on and rejected_on <= date)
    return :written_off if (written_off_on and written_off_on <= date)
    total_received_up_to(date) >= total_to_be_received ? :repaid : :outstanding
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
    s = status  # TODO: replace with case-when constuct
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
  

  # THE RUNNER.. this methods refreshes the history(/future) of this lone when
  # changes have been made to it, or its payments. gets called by hooks
  # the task of updating the history may take some time and it therefor put
  # the the Merb::Dispatcher.work_queue (using Merb.run_later)
  def update_history
    return if history_disabled  # easy when doing mass db modifications (like with fixutes)
    update_history_now
#     Merb.run_later { update_history_now }  # i just love procrastination
  end
  def update_history_now  # TODO: not update every thing all the time (like in case of a new payment)
    Merb.logger.error! "could not destroy the history" unless self.history.destroy!
    dates = payment_dates + installment_dates
#     dates << scheduled_disbursal_date if scheduled_disbursal_date
    dates << disbursal_date if disbursal_date
    dates << written_off_on if written_off_on
    dates.uniq.sort.each do |date|
      LoanHistory.write_for(self, date)
    end
  end


  # the arithmic of shifting by the installment_frequency (especially months is tricky)
  # used by many other methods, it accepts a negative +number+
  def shift_date_by_installments(date, number)
    return date if number == 0
    case installment_frequency
      when :daily
        return date + number
      when :weekly
        return date + number * 7
      when :biweekly
        return date + number * 14
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
        return Time.gm(new_year, new_month, new_day).to_date
      else
        raise ArgumentError.new("Strange period you got..")
    end
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

  alias :set_fees_without_updating_total :fees=
  def fees=(fees)
    set_fees_without_updating_total fees
    update_fees_total
  end

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
    repository.adapter.query(%Q{
      SELECT "received_on" FROM "payments"    -- the payment dates
       WHERE ("deleted_at" IS NULL) AND ("loan_id" = #{self.id})}).map { |x| Date.parse(x) }
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

