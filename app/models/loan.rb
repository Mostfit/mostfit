class Loan
  include DataMapper::Resource
  include FeesContainer
  include Identified
  include Pdf::LoanSchedule if PDF_WRITER

  DAYS = [:none, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]

  before :valid?,  :parse_dates
  before :valid?,  :convert_blank_to_nil
  before :save,    :update_scheduled_maturity_date
  after  :save,    :update_history_caller  # also seems to do updates
  after  :save,    :levy_fees
  after  :create,  :update_cycle_number
  before :destroy, :verified_cannot_be_deleted
  #  after  :destroy, :update_history

  attr_accessor :history_disabled  # set to true to disable history writing by this object
  attr_accessor :interest_percentage
  attr_accessor :already_updated

  property :id,                             Serial
  property :discriminator,                  Discriminator, :nullable => false, :index => true

  property :amount,                         Float, :nullable => false, :index => true  # this is the disbursed amount
  property :amount_applied_for,             Float, :index => true
  property :amount_sanctioned,              Float, :index => true

  property :interest_rate,                  Float, :nullable => false, :index => true
  property :installment_frequency,          Enum.send('[]', *INSTALLMENT_FREQUENCIES), :nullable => false, :index => true
  property :number_of_installments,         Integer, :nullable => false, :index => true
  property :weekly_off,                     Integer, :nullable => true # cwday pls
  property :client_id,                      Integer, :nullable => false, :index => true

  property :scheduled_disbursal_date,       Date, :nullable => false, :auto_validation => false, :index => true
  property :scheduled_first_payment_date,   Date, :nullable => false, :auto_validation => false, :index => true
  property :applied_on,                     Date, :nullable => false, :auto_validation => false, :index => true, :default => Date.today
  property :approved_on,                    Date, :auto_validation => false, :index => true
  property :rejected_on,                    Date, :auto_validation => false, :index => true
  property :disbursal_date,                 Date, :auto_validation => false, :index => true
  property :written_off_on,                 Date, :auto_validation => false, :index => true
  property :suggested_written_off_on,       Date, :auto_validation => false, :index => true
  property :write_off_rejected_on,          Date, :auto_validation => false, :index => true
  property :validated_on,                   Date, :auto_validation => false, :index => true
  property :preclosed_on,                   Date, :auto_validation => false, :index => true
  
  property :validation_comment,             Text
  property :created_at,                     DateTime, :index => true, :default => Time.now
  property :updated_at,                     DateTime, :index => true
  property :deleted_at,                     ParanoidDateTime
  property :loan_product_id,                Integer,  :index => true

  property :applied_by_staff_id,               Integer, :nullable => true, :index => true
  property :approved_by_staff_id,              Integer, :nullable => true, :index => true
  property :rejected_by_staff_id,              Integer, :nullable => true, :index => true
  property :disbursed_by_staff_id,             Integer, :nullable => true, :index => true
  property :written_off_by_staff_id,           Integer, :nullable => true, :index => true
  property :preclosed_by_staff_id,             Integer, :nullable => true, :index => true
  property :suggested_written_off_by_staff_id, Integer, :nullable => true, :index => true
  property :write_off_rejected_by_staff_id,    Integer, :nullable => true, :index => true
  property :validated_by_staff_id,             Integer, :nullable => true, :index => true
  property :verified_by_user_id,               Integer, :nullable => true, :index => true
  property :created_by_user_id,                Integer, :nullable => true, :index => true
  property :cheque_number,                     String,  :length => 20, :nullable => true, :index => true
  property :cycle_number,                      Integer, :default => 1, :nullable => false, :index => true

  #these amount and disbursal dates are required for TakeOver loan types. 
  property :original_amount,                    Integer
  property :original_disbursal_date,            Date
  property :original_first_payment_date,        Date
  property :taken_over_on,                      Date
  property :taken_over_on_installment_number,   Integer

  property :loan_utilization_id,                Integer, :lazy => true, :nullable => true
  property :under_claim_settlement,             Date, :nullable => true

  property :_scheduled_maturity_date,           Date

  # Caching baby!

  property :staleness_frequency, Integer

  property :c_center_id, Integer
  property :c_branch_id, Integer
  property :c_scheduled_maturity_date, Date
  property :c_maturity_date, Date
  property :c_actual_first_payment_date, Date
  property :c_last_status, Integer
  property :c_principal_received, Float
  property :c_interest_received, Float
  property :c_last_payment_received_on, Date
  property :c_last_payment_id, Integer
  property :c_stale?, Boolean
  
#  property :taken_over_on,                     Date
#  property :taken_over_on_installment_number,  Integer 

  # associations
  belongs_to :client
  belongs_to :funding_line, :nullable => true
  belongs_to :loan_product
  belongs_to :occupation,                :nullable  => true
  belongs_to :applied_by,                :child_key => [:applied_by_staff_id],                :model => 'StaffMember'
  belongs_to :approved_by,               :child_key => [:approved_by_staff_id],               :model => 'StaffMember'
  belongs_to :rejected_by,               :child_key => [:rejected_by_staff_id],               :model => 'StaffMember'
  belongs_to :disbursed_by,              :child_key => [:disbursed_by_staff_id],              :model => 'StaffMember'
  belongs_to :written_off_by,            :child_key => [:written_off_by_staff_id],            :model => 'StaffMember'
  belongs_to :preclosed_by,              :child_key => [:preclosed_by_staff_id],            :model => 'StaffMember'
  belongs_to :suggested_written_off_by,  :child_key => [:suggested_written_off_by_staff_id],  :model => 'StaffMember'
  belongs_to :write_off_rejected_by,     :child_key => [:write_off_rejected_by_staff_id],     :model => 'StaffMember' 
  belongs_to :validated_by,              :child_key => [:validated_by_staff_id],              :model => 'StaffMember'
  belongs_to :created_by,                :child_key => [:created_by_user_id],                 :model => 'User'
  belongs_to :loan_utilization
  belongs_to :verified_by,               :child_key => [:verified_by_user_id],                :model => 'User'

  has n, :loan_history,                                                                       :model => 'LoanHistory'
  has n, :payments
  has n, :audit_trails,       :child_key => [:auditable_id], :auditable_type => "Loan"
  has n, :portfolio_loans
  has 1, :insurance_policy
  has n, :applicable_fees,    :child_key => [:applicable_id], :applicable_type => "Loan"
  #validations

  validates_present      :client, :scheduled_disbursal_date, :scheduled_first_payment_date, :applied_by, :applied_on

  validates_with_method  :amount,                       :method => :amount_greater_than_zero?
  validates_with_method  :interest_rate,                :method => :interest_rate_greater_than_or_equal_to_zero?
  validates_with_method  :number_of_installments,       :method => :number_of_installments_greater_than_zero?
  validates_with_method  :applied_on,                   :method => :applied_before_appoved?
  validates_with_method  :approved_on,                  :method => :applied_before_appoved?
  validates_with_method  :applied_on,                   :method => :applied_before_rejected?
  validates_with_method  :rejected_on,                  :method => :applied_before_rejected?
  validates_with_method  :approved_on,                  :method => :approved_before_disbursed?
  validates_with_method  :disbursal_date,               :method => :approved_before_disbursed?
  validates_with_method  :disbursal_date,               :method => :disbursed_before_written_off?
  validates_with_method  :written_off_on,               :method => :disbursed_before_written_off?
  validates_with_method  :suggested_written_off_on,     :method => :disbursed_before_suggested_written_off?
  validates_with_method  :write_off_rejected_on,        :method => :disbursed_before_write_off_rejected?
  validates_with_method  :write_off_rejected_on,        :method => :rejected_before_suggested_write_off?
  validates_with_method  :disbursal_date,               :method => :disbursed_before_validated?
  validates_with_method  :validated_on,                 :method => :disbursed_before_validated?
  validates_with_method  :approved_on,                  :method => :applied_before_scheduled_to_be_disbursed?
  validates_with_method  :scheduled_disbursal_date,     :method => :applied_before_scheduled_to_be_disbursed?
  validates_with_method  :approved_on,                  :method => :properly_approved?
  validates_with_method  :approved_by,                  :method => :properly_approved?
  validates_with_method  :rejected_on,                  :method => :properly_rejected?
  validates_with_method  :rejected_by,                  :method => :properly_rejected?
  validates_with_method  :written_off_on,               :method => :properly_written_off?
  validates_with_method  :suggested_written_off_on,     :method => :properly_suggested_for_written_off?
  validates_with_method  :write_off_rejected_on,        :method => :properly_write_off_rejected?
  validates_with_method  :written_off_by,               :method => :properly_written_off?
  validates_with_method  :suggested_written_off_by,     :method => :properly_suggested_for_written_off?
  validates_with_method  :write_off_rejected_by,        :method => :properly_write_off_rejected?
  validates_with_method  :disbursal_date,               :method => :properly_disbursed?
  validates_with_method  :disbursed_by,                 :method => :properly_disbursed?
  validates_with_method  :validated_on,                 :method => :properly_validated?
  validates_with_method  :validated_by,                 :method => :properly_validated?
  validates_with_method  :scheduled_first_payment_date, :method => :scheduled_disbursal_before_scheduled_first_payment?
  validates_with_method  :scheduled_disbursal_date,     :method => :scheduled_disbursal_before_scheduled_first_payment?
  validates_with_method  :cheque_number,                :method => :check_validity_of_cheque_number
  validates_with_method  :client_active,                :method => :is_client_active
  validates_with_method  :verified_by_user_id,          :method => :verified_cannot_be_deleted, :if => Proc.new{|x| x.deleted_at != nil}

  #product validations

  validates_with_method  :amount,                       :method => :is_valid_loan_product_amount
  validates_with_method  :interest_rate,                :method => :is_valid_loan_product_interest_rate
  validates_with_method  :number_of_installments,       :method => :is_valid_loan_product_number_of_installments
  validates_with_method  :clients,                      :method => :check_client_sincerity
  validates_with_method  :insurance_policy,             :method => :check_insurance_policy    

  def self.display_name
    "Loan"
  end

  def check_validity_of_cheque_number
    return true if not self.cheque_number or (self.cheque_number and self.cheque_number.blank?)
    return [false, "This cheque is already used"] if Loan.all(:cheque_number => self.cheque_number, :id.not => self.id).count>0
    return true
  end

  def self.from_csv(row, headers, funding_lines)
    interest_rate = (row[headers[:interest_rate]].to_f>1 ? row[headers[:interest_rate]].to_f/100 : row[headers[:interest_rate]].to_f)
    
    obj = new(:loan_product => LoanProduct.first(:name => row[headers[:product]]), :amount => row[headers[:amount]],
              :interest_rate => interest_rate,
              :installment_frequency => row[headers[:installment_frequency]].downcase, :number_of_installments => row[headers[:number_of_installments]],
              :scheduled_disbursal_date => Date.parse(row[headers[:scheduled_disbursal_date]]),
              :scheduled_first_payment_date => Date.parse(row[headers[:scheduled_first_payment_date]]),
              :applied_on => Date.parse(row[headers[:applied_on]]), :approved_on => Date.parse(row[headers[:approved_on]]),
              :disbursal_date => Date.parse(row[headers[:disbursal_date]]),
              :disbursed_by_staff_id => StaffMember.first(:name => row[headers[:disbursed_by_staff]]).id,
              :funding_line_id => funding_lines[row[headers[:funding_line_serial_number]]].id,
              :applied_by_staff_id => StaffMember.first(:name => row[headers[:applied_by_staff]]).id,
              :approved_by_staff_id => StaffMember.first(:name => row[headers[:approved_by_staff]]).id,
              :client => Client.first(:reference => row[headers[:client_reference]]))
    obj.history_disabled=true
    [obj.save, obj]
  end

  def is_valid_loan_product_amount; is_valid_loan_product(:amount); end
  def is_valid_loan_product_interest_rate; is_valid_loan_product(:interest_rate); end
  def is_valid_loan_product_number_of_installments; is_valid_loan_product(:number_of_installments); end

  def is_valid_loan_product(method)
    loan_attr    = self.send(method)
    return [false, "No #{method} specified"] if not loan_attr or loan_attr===""
    return [false, "No loan product chosen"] unless self.loan_product
    product = self.loan_product
    #Checking if the loan adheres to minimum and maximums of the loan product
    {:min => :minimum, :max => :maximum}.each{|k, v|
      product_attr = product.send("#{k}_#{method}")
      if method==:interest_rate
        product_attr = product_attr.to_f/100
        loan_attr    = loan_attr.to_f
      end

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
      remainder = loan_attr.remainder(product_attr)
      remainder = remainder/100 if method==:interest_rate
      return  [false, "#{method.to_s.capitalize} should be in multiples of #{product_attr}"]  if not loan_attr or remainder > EPSILON
    end
    return true
  end


  # MISC FUNCTIONS
  def description
    "#{id}:Rs. #{amount} @ #{interest_rate} for client #{client.name}"
  end

  def short_tag
    "#{id}:Rs. #{amount} @ #{interest_rate}"
  end

  def info(date = Date.today)
    LoanHistory.first(:loan_id => id, :date.lte => date, :order => [:date.desc], :limit => 1)
  end

  def _show_cf(width = 10, padding = 4) #convenience function to see cashflow in console
    ps = payment_schedule
    titles = [:date, :total_balance, :balance, :principal, :interest, :total_paid, :total_principal, :total_interest, :fees]
    puts titles.map{|t| t.to_s[0..width - 1].rjust(width - padding/2).ljust(width)}.join("|")
    ps.keys.sort.each do |d| 
      ps[d][:total_paid] = ps[d][:principal] + ps[d][:interest]
      puts ([d.to_s] + titles[1..-1].map{|t| ps[d][t].round(4)}).map{|s| s.to_s.rjust(width - padding/2).ljust(width)}.join("|")
    end
  end

  def _show_ps
    puts payment_schedule.sort.map{|d, h| [d, h[:principal], h[:interest], h[:fees], h[:total_principal], h[:total_interest], h[:total]].join("\t")}.join("\n")
  end


  def self.search(q, per_page)
    if /^\d+$/.match(q)
      all(:conditions => {:id => q}, :limit => per_page)
    end
  end

  #return installment frequencies in days
  def installment_frequency_in_days
    case installment_frequency
    when :weekly
      7
    when :daily
      1
    when :monthly
      30
    when :biweekly
      14
    when :quadweekly
      28
    end
  end

  def clear_cache
    @payments_cache = @schedule = @history_array = @fee_schedule = @hols = @_installment_dates = nil
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

  def grt_date
    client.grt_pass_date
  end

  # the arithmic of shifting by the installment_frequency (especially months is tricky)
  # used by many other methods, it accepts a negative +number+
  # TODO: decide if we should make sure returned date is a payment date.
  def shift_date_by_installments(date, number, ensure_meeting_day = true)
    return date.holiday_bump if number == 0
    case installment_frequency
    when :daily
      new_date =  date + number
    when :weekly
      new_date =  date + number * 7
    when :biweekly
      new_date = date + number * 14
    when :quadweekly
      new_date = date + number * 28
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
    
    # take care of date changes in weekly schedules
    if [:weekly, :biweekly, :quadweekly].include?(installment_frequency) and cl=self.client(:fields => [:id, :center_id]) and cen=cl.center and cen.meeting_day != :none and ensure_meeting_day
      unless (new_date.weekday == cen.meeting_day_for(new_date) or (cen.meeting_day_for(new_date) == :none))
        # got wrong val. recalculate
        next_date = cen.next_meeting_date_from(new_date)
        prev_date = cen.previous_meeting_date_from(new_date)
        new_date  = (next_date.cweek == new_date.cweek ? next_date : prev_date)
      end
      #new_date - new_date.cwday + Center.meeting_days.index(client.center.meeting_day)
    end
    new_date.holiday_bump
  end

  def self.description
    "This is the description of the build-in master loan type. Typically you only deal with loan that are derived of this loan type."
  end

  def description
    "#{amount} @ #{interest_percentage}%"
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


  def repay(input, user, received_on, received_by, defer_update = false, style = NORMAL_REPAYMENT_STYLE, context = :default, desktop_id = nil, origin = nil)
    pmts = get_payments(input, user, received_on, received_by, defer_update, style, context, desktop_id, origin)
    x = make_payments(pmts, context, defer_update)
    x
  end

  def get_payments(input, user, received_on, received_by, defer_update = false, style = NORMAL_REPAYMENT_STYLE, context = :default, desktop_id = nil, origin = nil)
    # this is the way to repay loans, _not_ directly on the Payment model
    # this to allow validations on the Payment to be implemented in (subclasses of) the Loan
    unless input.is_a? Array or input.is_a? Fixnum or input.is_a? Float or input.is_a?(Hash)
      raise "the input argument of Loan#repay should be of class Fixnum or Array"
    end
    raise "cannot repay a loan that has not been saved" if new?

    principal, interest, total, fees_paid = 0, 0, nil, 0
    if input.is_a? Fixnum or input.is_a? Float  # in case only one amount is specified
      # interest is paid first, the rest goes in as principal
      # the payment is filed on received_on without knowing about the future
      # it could happen that payment have been made after this payment
      # here the validations on the Payment should
      if style == NORMAL_REPAYMENT_STYLE
        total        = input
        total_fees_due_on_date = total_fees_payable_on(received_on)
        fees_paid    = [total, total_fees_due_on_date].min
        total        = input - fees_paid
        interest_due = [(-interest_overpaid_on(received_on)), 0].max
        interest     = [interest_due, total].min  # never more than total
        principal    = total - interest
      elsif style == PRORATA_REPAYMENT_STYLE #does not pay fees
        interest, principal = pay_prorata(input, received_on)
      end
    elsif input.is_a? Array  # in case principal and interest are specified separately
      principal, interest = input[0], input[1]
    elsif input.is_a? Hash
      fees_paid = input[:fees]
      interest = input[:interest]
      principal = input[:principal]
    end
    
    save_status = nil
    payments = []
    if fees_paid > 0
      fee_payment = Payment.new(:loan => self, :created_by => user,
                                :received_on => received_on, :received_by => received_by,
                                :amount => fees_paid.round(2), :type => :fees, :desktop_id => desktop_id, :origin => origin)
      payments.push(fee_payment)
    end
    if interest > 0
      int_payment = Payment.new(:loan => self, :created_by => user,
                                :received_on => received_on, :received_by => received_by,
                                :amount => interest.round(2), :type => :interest, :desktop_id => desktop_id, :origin => origin)
      payments.push(int_payment)
    end
    if principal > 0
      prin_payment = Payment.new(:loan => self, :created_by => user,
                                 :received_on => received_on, :received_by => received_by,
                                 :amount => principal.round(2), :type => :principal, :desktop_id => desktop_id, :origin => origin)        
      payments.push(prin_payment)
    end
    payments             
  end

  def make_payments(payments, context = :default, defer_update = false)
    Payment.transaction do |t|
      self.history_disabled=true
      payments.each{|p| p.override_create_observer = true}    

      if payments.collect{|payment| payment.save(context)}.include?(false)
        t.rollback
        return [false, payments.find{|p| p.type==:principal}, payments.find{|p| p.type==:interest}, payments.find{|p| p.type==:fees},]        
      end
      AccountPaymentObserver.single_voucher_entry(payments)
    end
    unless defer_update #i.e. bulk updating loans
      self.history_disabled=false
      @already_updated=false
      update_history(true)  # update the history if we saved a payment
    end
    if payments.length > 0
      return [true, payments.find{|p| p.type==:principal}, payments.find{|p| p.type==:interest}, payments.find_all{|p| p.type==:fees}]
    else
      return [false, nil, nil, nil]
    end
    # return the success boolean and the payment object itself for further processing
  end

  # the way to delete payments from the db
  def delete_payment(payment, user)
    return false unless payment.loan.id == self.id
    payment.deleted_by = user
    if payment.destroy
      update_history
      clear_cache
      return [true, payment]
    end
    [false, payment]
  end

  def get_fee_payments(amount, date, received_by, created_by)
    fees = []
    fp = fees_payable_on(date)
    fs = fee_schedule
    pay_order = fs.keys.sort.map{|d| fs[d].keys}.flatten.uniq
    pay_order.each do |k|
      if fp.has_key?(k)
        p = Payment.new(:amount => [fp[k],amount].min, :type => :fees, :received_on => date, :comment => k, :fee => k,
                        :received_by => received_by, :created_by => created_by, :client => client, :loan => self)
        amount -= p.amount
        fp[k]  -= p.amount
        fees << p if p.amount > 0
      end
    end
    fees
  end
    

  def pay_fees(amount, date, received_by, created_by)
    success, @prin, @int, @fees = make_payments(get_fee_payments(amount, date, received_by, created_by))
    return success, @fees
  end
  # LOAN INFO FUNCTIONS - CALCULATIONS

  def cash_flow(type = :scheduled, exclude_fees = false)
    # Hash of dates and +/- amounts. 
    # This differs from payment_schedule and payments_hash in that it includes fees. 
    # Perhaps it would be better if those functions returned a comprehensive listing, but for the time being, this is okay
    # TODO : make payments_hash and payment_schedule return comprehensve cashflows (i.e. fees,etc  as well.)
    fs = type == :scheduled ? product_fee_schedule : fees_paid
    fsh = fs.map{|f,v| [f,{:fees => v.values.inject(0){|a,b| a+b}}]}.to_hash
    cf  = type == :scheduled ? payment_schedule : payments_hash
    #Double counting of fees in case of ssame date first payment is happening here
    if (cf.values.collect{|x| x[:fees]||0}.inject(0){|s,x| s+=x} == 0)
      cf  += fsh
    end
    dd  = type == :scheduled ? scheduled_disbursal_date : disbursal_date
    cf  += {dd => {:principal => -amount}}
    rv  = cf.keys.sort.map{|k| v=cf[k];[k,(v[:principal] || 0) + (v[:interest] || 0) + (exclude_fees ? 0 : (v[:fees] || 0))]}
    return rv
  end

  def product_fee_schedule
    # This is for IRR calculation, so we can get the fee schedule for the loan product
    # So we don't have to save dummy loans when we design a product.
    @fee_schedule = {}
    klass_identifier = "loan"
    loan_product.fees.each do |f|
      type, *payable_on = f.payable_on.to_s.split("_")
      date = send(payable_on.join("_")) if type == klass_identifier
      if date.class==Date
        @fee_schedule += {date => {f => f.fees_for(self)}} unless date.nil?
      elsif date.class==Array
        date.each{|date|
          @fee_schedule += {date => {f => f.fees_for(self)}} unless date.nil?
        }
      end
    end
    @fee_schedule
  end


  def irr(exclude_fees = false,iterations = 100)
    begin
      cf = cash_flow(:scheduled, exclude_fees)
      min_date = cf[0][0]
      rv = (1..iterations).inject do |rate,|
        # trust me, this is correct. i think
        i = 1
        npv_map = cf.map do |x| 
          yn = ((x[0]-min_date) / get_reciprocal).round
          yd = get_divider
          yf = yn / yd.to_f
          df = [1/(1+(yf*rate)),x[1]]
          df
        end
        npv = npv_map.inject(0){|a,b| a + (b[0]*b[1])}
        rate * (1 - npv / -amount)
      end
    rescue
      "NaN"
    end
  end

  def first_payment_date
    if self.disbursal_date
      shift_date_by_installments(self.disbursal_date, 1)
    else
      nil
    end
  end


  def actual_number_of_installments
    # we need this beacuse in laons with rounding, you may end up with more/less installments than advertised!!
    # crazy MFI product managers!!!
    number_of_installments
  end

  def payment_schedule
    # this is the fount of all knowledge regarding the scheduled payments for the loan. 
    # it feeds into every other calculation about the loan schedule such as get_scheduled, calculate_history, etc.
    # if this is wrong, everything about this loan is wrong.
    return @schedule if @schedule
    @schedule = {}
    return @schedule unless amount.to_f > 0

    #if self.respond_to?(:repayment_style) and self.repayment_style
    #  extend Kernel.module_eval("Mostfit::RepaymentStyles:#{repayment_style.camel_case}")
    #end

    principal_so_far = interest_so_far = fees_so_far = total = 0
    balance = amount
    fs = fee_schedule
    dd = disbursal_date || scheduled_disbursal_date
    fees_so_far = fs.has_key?(dd) ? fs[dd].values.inject(0){|a,b| a+b} : 0

    @schedule[dd] = {:principal => 0, :interest => 0, :total_principal => 0, :total_interest => 0, :balance => balance, :total => 0, :fees => fees_so_far}

    repayed =  false

    ensure_meeting_day = false
    # commenting this code so that meeting dates not automatically set
    #ensure_meeting_day = [:weekly, :biweekly].include?(installment_frequency)
    ensure_meeting_day = true if self.loan_product.loan_validations and self.loan_product.loan_validations.include?(:scheduled_dates_must_be_center_meeting_days)
    (1..actual_number_of_installments).each do |number|
      date      = installment_dates[number-1] #shift_date_by_installments(scheduled_first_payment_date, number - 1, ensure_meeting_day)
      principal = scheduled_principal_for_installment(number)
      interest  = scheduled_interest_for_installment(number)
      next if repayed
      repayed   = true if amount <= principal_received_up_to(date)
      
      principal_so_far += principal
      interest_so_far  += interest
      fees = fs.has_key?(date) ? fs[date].values.inject(0){|a,b| a+b} : 0
      fees_so_far += fees || 0
      balance -= principal
      @schedule[date] = {
        :principal                  => principal,
        :interest                   => interest,
        :fees                       => fees,
        :total_principal            => (principal_so_far),
        :total_interest             => (interest_so_far),
        :total                      => (principal_so_far + interest_so_far).round(2),
        :balance                    => balance.round(2),
      }
    end
    # we have to do the following to avoid the circular reference from total_to_be_received.
    total = @schedule[@schedule.keys.max][:total]
    @schedule.each { |k,v| v[:total_balance] = (total - v[:total]).round(2)}
    @schedule
  end

  
  def payments_hash
    # this is the fount of knowledge for actual payments on the loan
    return @payments_cache if @payments_cache
    sql = %Q{
        SELECT SUM(amount * IF(type=1,1,0)) AS principal,
               SUM(amount * IF(type=2,1,0)) AS interest,
               received_on
        FROM payments
        WHERE (deleted_at IS NULL) AND (loan_id = #{self.id})
        GROUP BY received_on ORDER BY received_on}
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
        :principal                 => payment.principal,
        :interest                  => payment.interest,
        :total_principal           => (principal += payment.principal),
        :total_interest            => (interest  += payment.interest),
        :total                     => (total     += payment.principal + payment.interest),
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

  def _show_ph
    puts payments_hash.sort.map{|d, h|
      [
       d, h[:principal].to_i, h[:interest].to_i, h[:total_principal].to_i, h[:total_interest].to_i, h[:total].to_i, h[:balance].to_i, h[:total_balance].to_i
      ].join("\t")
    }.join("\n")
  end
  
  # LOAN INFO FUNCTIONS - SCHEDULED

  # these 2 methods define the pay back scheme
  # These are ONE BASED
  # typically reimplemented in subclasses
  def scheduled_principal_for_installment(number)
    # number unused in this implentation, subclasses may decide differently
    # therefor always supply number, so it works for all implementations
    raise "number out of range, got #{number}" if number < 1 or number > actual_number_of_installments
    (amount.to_f / number_of_installments).round(2)
  end
  def scheduled_interest_for_installment(number)  # typically reimplemented in subclasses
    # number unused in this implentation, subclasses may decide differently
    # therefor always supply number, so it works for all implementations
    raise "number out of range, got #{number}" if number < 1 or number > actual_number_of_installments
    (amount * interest_rate / number_of_installments).round(2)
  end

  # These info functions need not be overridden in derived classes.
  # We attmept to achieve speed by caching values for the duration of a request through a payment_schedule function
  # Later we write functions for
  #    scheduled_[principal, interest, total]_to_be_received
  #    scheduled_[principal, interest, total]_up_to(date)
  #    scheduled_[principal, interest, total]_on(date)

  def total_principal_to_be_received; payment_schedule.map{|k,v| v[:principal]}.reduce(:+); end
  def total_interest_to_be_received; payment_schedule.map{|k,v| v[:interest]}.reduce(:+); end
  def total_to_be_received
    ((total_principal_to_be_received>0 ? total_principal_to_be_received : amount) + total_interest_to_be_received)
  end

  def scheduled_principal_up_to(date); get_scheduled(:total_principal, date); end
  def scheduled_interest_up_to(date);  get_scheduled(:total_interest,  date); end
  def scheduled_total_up_to(date); (scheduled_principal_up_to(date) + scheduled_interest_up_to(date));  end


  def scheduled_principal_due_on(date); get_scheduled(:principal, date); end
  def scheduled_interest_due_on(date); get_scheduled(:interest, date); end
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
             when  :quadweekly
             then  ((date - scheduled_first_payment_date).to_f / 28).floor + 1
             when  :monthly
             then  count = 1
               while shift_date_by_installments(date, -count) >= scheduled_first_payment_date and count < actual_number_of_installments
                 count += 1
               end
               count
             else
               raise ArgumentError.new("Strange period you got..")
             end
    [result, actual_number_of_installments].min  # never return more than the number_of_installments
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

  # these 3 method1 return overpayment amounts (PAYMENT-RECEIVED perspective)
  # negative values mean shortfall (we're positive-minded at intellecap)
  def principal_overpaid_on(date)
    (principal_received_up_to(date) - scheduled_principal_up_to(date))
  end
  def interest_overpaid_on(date)
    (interest_received_up_to(date) - scheduled_interest_up_to(date))
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

    return :applied_in_future    if applied_on.holiday_bump > date  # non existant
    return :pending_approval     if applied_on.holiday_bump <= date and
                                 not (approved_on and approved_on.holiday_bump <= date) and
                                 not (rejected_on and rejected_on.holiday_bump <= date)
    return :approved             if (approved_on and approved_on.holiday_bump <= date) and not (disbursal_date and disbursal_date.holiday_bump <= date) and 
                                 not (rejected_on and rejected_on.holiday_bump <= date)
    return :rejected             if (rejected_on and rejected_on.holiday_bump <= date)
    return :written_off          if (written_off_on and written_off_on <= date)
    return :preclosed            if (preclosed_on and preclosed_on <= date)
    return :claim_settlement     if under_claim_settlement and under_claim_settlement.holiday_bump <= date
    total_received ||= total_received_up_to(date)
    principal_received ||= principal_received_up_to(date)
    return :disbursed            if (date == disbursal_date.holiday_bump) and total_received < total_to_be_received
    if total_received >= total_to_be_received
      @status =  :repaid
    elsif (amount - principal_received) <= EPSILON and scheduled_interest_up_to(date)<=interest_received_up_to(Date.today)
      @status =  :repaid
    elsif amount<=principal_received
      @status =  :repaid
    else
      @status =  :outstanding
    end
  end
  
  # LOAN INFO FUNCTIONS - DATES
  def installment_for_date(date = Date.today)
    installment_dates.select{|d| d <= date}.count
  end
  def date_for_installment(number)
    shift_date_by_installments(scheduled_first_payment_date, number-1)
  end
  def scheduled_maturity_date
    payment_schedule.keys.max
  end
  def scheduled_repaid_on
    # first payment is on "scheduled_first_payment_date", so number_of_installments-1 periods later
    # we find the scheduled_repaid_on date.
    scheduled_maturity_date
  end
  # the installment dates
  def installment_dates
    return @_installment_dates if @_installment_dates
    if installment_frequency == :daily
      # we have to br careful that when we do a holiday bump, we do not get stuck in an endless loop
      ld = scheduled_first_payment_date - 1
      @_installment_dates = []
      (1..number_of_installments).each do |i|
        ld += 1
        if ld.cwday == weekly_off
          ld +=1
        end
        if ld.holiday_bump.cwday == weekly_off # endless loop
          ld.holiday_bump(:after)
        end
        @_installment_dates << ld
      end
      return @_installment_dates
    end
        
    ensure_meeting_day = false
    ensure_meeting_day = [:weekly, :biweekly].include?(installment_frequency)
    ensure_meeting_day = true if self.loan_product.loan_validations and self.loan_product.loan_validations.include?(:scheduled_dates_must_be_center_meeting_days)
    @_installment_dates = (0..(actual_number_of_installments-1)).to_a.map {|x| shift_date_by_installments(scheduled_first_payment_date, x, ensure_meeting_day) }    
  end

  #Increment/sync the loan cycle number. All the past loans which are disbursed are counted
  def update_cycle_number
    self.cycle_number=self.client.loans(:id.lt => id, :disbursal_date.not => nil).count+1
  end

  # HISTORY
  def update_history_caller
    update_history(false)
  end
  
  # Moved this method here from instead of the LoanHistory model for purposes of speed. We sacrifice a bit of readability
  # for brute force iterations and caching => speed
  def update_history(forced=false)
    return true if Mfi.first.dirty_queue_enabled and DirtyLoan.add(self) and not forced
    return if @already_updated and not forced
    return if self.history_disabled and not forced# easy when doing mass db modifications (like with fixutes)
    clear_cache
    update_history_bulk_insert
    @already_updated=true
  end

  def calculate_history
    return @history_array if @history_array
    # Crazy heisenbug is fixed by prefetching payments hash
    payments_hash
    t = Time.now; @history_array = []
    dates = ([applied_on, approved_on, scheduled_disbursal_date, disbursal_date, written_off_on, scheduled_first_payment_date].map{|d|
               d.holiday_bump if d.is_a?(Date)
             } + payment_dates + installment_dates).compact.uniq.sort
    last_paid_date = nil

    repayed=false
    dates.each_with_index do |date,i|
      current   = date == Date.today ? true : (((dates[[i,0].max] < Date.today and dates[[dates.size - 1,i+1].min] > Date.today) or 
                   (i == dates.size - 1 and dates[i] < Date.today)))
      scheduled = get_scheduled(:all, date)
      actual    = get_actual(:all, date)
      prin      = principal_received_on(date)
      int       = interest_received_on(date)
      if (actual[:total_balance] - scheduled[:total_balance] > prin + int) and date >= scheduled_first_payment_date # there is a default
        last_paid_date ||= dates[[i,dates.size-1].min];        days_overdue = [0,date - last_paid_date].max
      else
        last_paid_date = nil;        days_overdue = 0
      end
      next if repayed
      principal_due  = actual[:balance] - scheduled[:balance]
      interest_due   = actual[:total_balance] - scheduled[:total_balance] - (actual[:balance] - scheduled[:balance])
      repayed = true if actual[:balance]<=0 and interest_due<=0

      @history_array << {
        :loan_id                             => id,
        :date                                => date,
        :status                              => STATUSES.index(get_status(date)) + 1,
        :scheduled_outstanding_principal     => scheduled[:balance].round(2),
        :scheduled_outstanding_total         => scheduled[:total_balance].round(2),
        :actual_outstanding_principal        => actual[:balance].round(2),
        :actual_outstanding_total            => actual[:total_balance].round(2),
        :amount_in_default                   => actual[:balance].round(2) - scheduled[:balance].round(2),
        :days_overdue                        => days_overdue, 
        :current                             => current,
        :principal_due                       => principal_due.round(2), 
        :interest_due                        => interest_due.round(2),
        :principal_paid                      => prin.round(2),
        :interest_paid                       => int.round(2)
      }
    end
    Merb.logger.info "History calculation took #{Time.now - t} seconds"
    @history_array
  end

  def _show_his(width = 10, padding = 4)
    titles = {:date => :date, :sched_total => :scheduled_outstanding_total, :sched_bal => :scheduled_outstanding_principal,
      :prin_paid => :principal_paid, :prin_due => :principal_due, :int_paid => :interest_paid, :int_due => :interest_due}
    title_order = [:date, :sched_total, :sched_bal, :prin_paid, :prin_due, :int_paid, :int_due]
    hist = calculate_history.sort_by{|x| x[:date]}
    puts title_order.map{|t| t.to_s.rjust(width - padding/2).ljust(width)}.join("|")
    hist.each do |h|
      puts (["#{h[:date]}\t"] + title_order[1..-1].map{|t| h[titles[t]].round(4)}.map{|v| v.to_s}.map{|s| s.rjust(width - padding/2).ljust(width)}).join("|")
    end
  end

  def update_history_bulk_insert
    # this gets the history from calculate_history and does one single insert into the database
    t = Time.now
    Merb.logger.error! "could not destroy the history" unless self.loan_history.destroy!
    d0 = Date.parse('2000-01-03')
    sql = %Q{ INSERT INTO loan_history(loan_id, date, status, scheduled_outstanding_principal, scheduled_outstanding_total,
                                       actual_outstanding_principal, actual_outstanding_total, current, amount_in_default, client_group_id, center_id, client_id, 
                                       branch_id, days_overdue, week_id, principal_due, interest_due, principal_paid, interest_paid, created_at)
              VALUES }
    values = []
    calculate_history.each do |history|
      value = %Q{(#{id}, '#{history[:date].strftime('%Y-%m-%d')}', #{history[:status]}, #{history[:scheduled_outstanding_principal]},
                          #{history[:scheduled_outstanding_total]}, #{history[:actual_outstanding_principal]},
                          #{history[:actual_outstanding_total]},#{history[:current] ? 1 : 0}, #{history[:amount_in_default]}, #{client.client_group_id || "NULL"}, 
                          #{client.center.id},#{client.id},#{client.center.branch.id}, #{history[:days_overdue]}, #{((history[:date] - d0) / 7).to_i + 1},
                          #{history[:principal_due]},#{history[:interest_due]}, #{history[:principal_paid]},#{history[:interest_paid]}, 
                          '#{DateTime.now.strftime("%Y-%m-%d %H:%M:%S")}')}
     values << value
    end
    sql += values.join(",") + ";"
    repository.adapter.execute(sql)
    Merb.logger.info "update_history_bulk_insert done in #{Time.now - t}"
    return true
  end
  
  def to_s
    id.to_s
  end

  def write_off(written_off_on_date, written_off_by_staff)
    if written_off_on_date and written_off_by_staff and not written_off_on_date.blank? and not written_off_by_staff.blank?
      self.written_off_on = written_off_on_date
      self.written_off_by = (written_off_by_staff.class == StaffMember ? written_off_by_staff : StaffMember.get(written_off_by_staff))
      self.valid?
      self.save_self
    else
      false
    end
  end


  include DateParser  # mixin for the hook "before :valid?, :parse_dates"
  include Misfit::LoanValidators

  def convert_blank_to_nil
    self.attributes.each{|k, v|
      if v.is_a?(String) and v.empty? and (self.class.send(k).type == Integer or self.class.send(k).type == Float)
        self.send("#{k}=", nil)
      end
    }
    self.amount      ||= self.amount_applied_for
  end

  def update_scheduled_maturity_date
    self._scheduled_maturity_date = scheduled_maturity_date if @schedule
  end

  # repayment styles
  def pay_prorata(total, received_on)
    #adds up the principal and interest amounts that can be paid with this amount and prorates the amount
    i = used = prin = int = 0.0
    d = received_on
    total = total.to_f
    while used < total
      prin += scheduled_principal_for_installment(installment_for_date(d))
      int  += scheduled_interest_for_installment(installment_for_date(d))
      used  = (prin + int)
      d = shift_date_by_installments(d, 1)
    end
    interest  = total * int/(prin + int)
    principal = total * prin/(prin + int)
    [interest, principal]
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
        col = cache[keys.min].merge(:balance => amount, :total_balance => total_to_be_received)
        rv = (column == :all ? col : col[column])
      elsif date >= keys.max
        rv = (column == :all ? cache[keys.max] : cache[keys.max][column])
      else
        keys.each_with_index do |k,i|
          if keys[[i+1,keys.size - 1].min] > date
            # http://thingsaaronmade.com/blog/ruby-shallow-copy-surprise.html
            rv = (column == :all ? Marshal.load(Marshal.dump(cache[k])) : cache[k][column])
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

  def get_scheduled(column, date) 
    payment_schedule if @schedule.nil?
    get_from_cache(payment_schedule, column, date)
  end

  def get_actual(column, date)
    payments_hash if @payments_cache.nil?
    get_from_cache(payments_hash, column, date)
  end

  ## validations: read their method name and error to see what they do.
  def dates_are_not_holidays
    h = ["scheduled_disbursal_date", "scheduled_first_payment_date"].map{|d| [d,Misfit::Config.holidays.include?(self.send(d))]}.reject{|e| e[1] == false}
    return true if h.blank?
    return [false, h.map{|f| f[0]}.join(", ") + " are holidays"]
  end
  def check_client_sincerity
    return [false, "Client is marked insincere and is not eligible for a loan"] if client and client.tags and client.tags.include?(:insincere)
    return true
  end

  def amount_greater_than_zero?
    return true if not amount.blank? and amount > 0
    [false, "Loan amount should be greater than zero"]
  end
  def interest_rate_greater_than_or_equal_to_zero?
    return true if interest_rate and interest_rate.to_f >= 0
    [false, "Interest rate should be greater than or equal to zero"]
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
  def disbursed_before_suggested_written_off?
    return true if suggested_written_off_on.blank? or (disbursal_date and suggested_written_off_on and disbursal_date <= suggested_written_off_on)
    [false, "Cannot be suggested for write off before the loan is disbursed"]
  end
  def disbursed_before_write_off_rejected?
    return true if write_off_rejected_on.blank? or (disbursal_date and write_off_rejected_on and disbursal_date <= write_off_rejected_on)
    [false, "Cannot be rejected before the loan is disbursed"]
  end
  def rejected_before_suggested_write_off?
    return true if suggested_written_off_on.blank? or (write_off_rejected_on and suggested_written_off_on and write_off_rejected_on >= suggested_written_off_on)
    [false, "Cannot reject a loan for write off before it is suggested for write off."]
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
    return [false, "Funding Line must be set before approval"] unless funding_line
    return true if (approved_on and (approved_by or approved_by_staff_id)) or (approved_on.blank? and (approved_by.blank? or approved_by_staff_id.blank?))
    [false, "The approval date and the staff member that approved the loan should both be given"]
  end
  def properly_rejected?
    return true if (rejected_on and rejected_by) or (rejected_on.blank? and rejected_by.blank?)
    [false, "The rejection date and the staff member that rejected the loan should both be given"]
  end
  def properly_write_off_rejected?
    return true if (write_off_rejected_on and write_off_rejected_by) or (write_off_rejected_on.blank? and write_off_rejected_by.blank?)
    [false, "The date and the staff member that rejected the write off should both be given"]
  end
  def properly_written_off?
    return true if (written_off_on and written_off_by) or (written_off_on.blank? and written_off_by.blank?)
    [false, "The date of writing off the loan and the staff member that wrote off the loan should both be given"]
  end
  def properly_suggested_for_written_off?
    return true if (suggested_written_off_on and suggested_written_off_by) or (suggested_written_off_on.blank? and suggested_written_off_by.blank?)
    [false, "The date of suggesting write off loan and staff member who is suggesting to write off the loan should both be given"]
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
  def is_client_active
    if client and not client.active and self.new?
      return [false, "This is client is no more active"]
    end
    return true
  end
  def verified_cannot_be_deleted
    return true unless verified_by_user_id
    throw :halt
  end
  
  def check_insurance_policy
    return true unless insurance_policy
    return [false, "Insurance Policy is not valid"] unless insurance_policy.valid?
    return true

  end

  def get_divider
    case installment_frequency
    when :weekly
      52
    when :biweekly
      26
    when :bi_weekly
      26
    when :monthly
      12
    when :daily
      365
    end    
  end


  def get_reciprocal
    case installment_frequency
    when :weekly
      7
    when :biweekly
      14
    when :monthly
      # TODO fix this
      31
    when :daily
      1
    end    
  end

  
end

class DefaultLoan < Loan
  # This is the "Default" loan type. It is nothing better of worse than its parent.
  # That explains the emptyness
  def self.display_name
    "Standard loan (Default Loan)"
  end

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
  def self.display_name
    "A50Loan - defunct"
  end
end

class EquatedWeekly < Loan
  # these 2 methods define the pay back scheme
  # typically reimplemented in subclasses
  include ExcelFormula
  # property :purpose,  String

  def self.display_name
    "Reducing balance schedule (Equated Weekly)"
  end

  def equated_payment
    pmt(interest_rate/get_divider, number_of_installments, amount, 0, 0)
  end

  def pay_prorata(total, received_on)
    i = used = prin = int = 0.0
    d = received_on
    total = total.to_f
    pmnt = equated_payment
    d = received_on
    curr_bal = actual_outstanding_principal_on(d)
    while (total - used) >= 0.01
      i_pmt = interest_rate/get_divider * curr_bal 
      int += i_pmt
      p_pmt = pmnt - i_pmt
      prin += p_pmt
      curr_bal -= p_pmt
      used  = (prin + int)
      d = shift_date_by_installments(d, 1)
    end
    interest  = total * int/(prin + int)
    principal = total * prin/(prin + int)
    [interest, principal]

  end

  def scheduled_principal_for_installment(number)
    # number unused in this implentation, subclasses may decide differently
    # therefor always supply number, so it works for all implementations
    raise "number out of range, got #{number} but max is #{number_of_installments}" if number < 0 or number > number_of_installments
    return reducing_schedule[number][:principal_payable]
  end

  def scheduled_interest_for_installment(number)  # typically reimplemented in subclasses
    # number unused in this implentation, subclasses may decide differently
    # therefor always supply number, so it works for all implementations
    raise "number out of range, got #{number}" if number < 0 or number > number_of_installments
    return reducing_schedule[number][:interest_payable]
  end

private
  def reducing_schedule
    return @reducing_schedule if @reducing_schedule
    @reducing_schedule = {}    
    balance = amount
    payment            = pmt(interest_rate/get_divider, number_of_installments, amount, 0, 0)
    1.upto(number_of_installments){|installment|
      @reducing_schedule[installment] = {}
      @reducing_schedule[installment][:interest_payable]  = ((balance * interest_rate) / get_divider).round(2)
      @reducing_schedule[installment][:principal_payable] = (payment - @reducing_schedule[installment][:interest_payable]).round(2)
      balance = balance - @reducing_schedule[installment][:principal_payable]
    }
    return @reducing_schedule
  end

  def get_divider
    case installment_frequency
    when :weekly
      52
    when :biweekly
      26
    when :monthly
      12
    when :daily
      365
    end    
  end
end


class BulletLoan < Loan
  before :save, :set_installments_to_1
  
  def self.display_name
    "Single shot repayment (Bullet Loan)"
  end

  def scheduled_interest_for_installment(number = 1)
    amount * interest_rate
  end
  
  def scheduled_principal_for_installment(number = 1)
    amount
  end

  def scheduled_interest_up_to(date)
    return scheduled_interest_for_installment(1) if date > scheduled_first_payment_date
    scheduled_interest_for_installment(1) * (1 - (scheduled_first_payment_date - date) / (scheduled_first_payment_date - disbursal_date||scheduled_disbursal_date))
  end

  def pay_prorata(total, received_on)
    #adds up the principal and interest amounts that can be paid with this amount and prorates the amount
    int  = scheduled_interest_up_to(received_on)
    int -= interest_received_up_to(received_on)
    prin = total - int
    [int, prin]
  end

  
  private
  def set_installments_to_1
    number_of_installments = 1
  end
end

class BulletLoanWithPeriodicInterest < BulletLoan
  def self.display_name
    "Single shot principal with periodic interest (Bullet Loan With Periodic Interest)"
  end
  
  def scheduled_interest_for_installment(number)
    raise "number out of range, got #{number}" if number < 1 or number > number_of_installments
    (amount * interest_rate / number_of_installments).to_i
  end

  def scheduled_principal_for_installment(number)
    return 0 if number < number_of_installments
    return amount if number == number_of_installments
  end
  
  def scheduled_interest_up_to(date);  get_scheduled(:total_interest,  date); end
end

class PararthRounded < Loan
  def self.display_name
    "Rounded schedule (Pararth Rounded)"
  end

  def scheduled_principal_for_installment(number)
    raise "number out of range, got #{number}" if number < 1 or number > number_of_installments
    rounding_schedule[number][:principal]
  end

  def scheduled_interest_for_installment(number)
    raise "number out of range, got #{number}" if number < 1 or number > number_of_installments
    rounding_schedule[number][:interest]
  end

  def rounding_schedule
    return @_rounding_schedule if @_rounding_schedule
    @_rounding_schedule = {}
    return @_rounding_schedule unless amount.to_f > 0
    _prin_per_installment = amount.to_f / number_of_installments
    _total = amount * (1 + interest_rate) # cannot use total_to_be_received without blowing the universe up
    _installment = _total / number_of_installments
    rf = 0;
    (1..number_of_installments).to_a.each do |i| 
      prin = (_prin_per_installment + rf).send(loan_product.rounding_style)
      rf = _prin_per_installment - prin + rf
      int = (_installment - prin).send(loan_product.rounding_style)
      @_rounding_schedule[i] =  {:principal => prin, :interest => int}
    end
    return @_rounding_schedule
  end

  def clear_cache
    super
    @_rounding_schedule = nil
  end

  # repayment styles
  def pay_prorata(total, received_on)
    #adds up the principal and interest amounts that can be paid with this amount and prorates the amount
    i = used = prin = int = 0.0
    d = received_on
    total = total.to_f
    while used < total
      prin -= principal_overpaid_on(d).round(2)
      int  -= interest_overpaid_on(d).round(2)
      used  = (prin + int)
      d = client.center.next_meeting_date_from(d)
    end
    interest  = total * int/(prin + int)
    principal = total * prin/(prin + int)
    pfloat    = principal - principal.to_i
    ifloat    = interest  - interest.to_i
    pfloat > ifloat ? [interest - ifloat, principal + ifloat] : [interest + pfloat, principal - pfloat]
  end
end


# TAKEOVER LOANS!!
# these loans are exisitng loans that are taken over by us. They work like this:
# We create a descendant of each Loan sublass and suffix it with Takeover. i.e. BulletLoanTakeover
# In our system, all payments are rebased from the installment we take it over from
# We do this once, generically, for any repayment schedule, by calling super and  rejecting anything from the loan schedule that does not belong to us
# Remember, the payments on the loan remain exactly the same as before for the customer.


(Loan.descendants.to_a - [Loan]).each do |c|
  k = Class.new(c)
  Object.const_set "TakeOver#{c.to_s}", k # we have to name it first otherwise DataMapper craps out
  Kernel.const_get("TakeOver#{c.to_s}").class_eval do
    before :valid?, :set_amount
    validates_with_method :original_properties_specified?
    validates_with_method :taken_over_properly?
    def self.display_name
      "Take over #{super}"
    end

    def set_amount
      # this sets the amount to be the outstanding amount unless it is already set
      amount = payment_schedule[payment_schedule.keys.min][:balance]
      amount_applied_for = amount
    end

    def original_properties_specified?
      blanks = []
      [:original_amount, :original_disbursal_date, :original_first_payment_date].each do |o|
        blanks << o.to_s.humanize if send(o).blank?
      end
      return true if blanks.blank?
      return [false, "#{blanks.join(',')} must be specified"]
    end

    def taken_over_properly?
      if taken_over_on_installment_number and (taken_over_on_installment_number < number_of_installments)
        return true

      elsif taken_over_on and (taken_over_on < scheduled_maturity_date)
        return true
      else
        return [false, "Takeover date or installment does not jive with this loan"]
      end
    end  

    def calculate_history
      super
      applied_on_date = self.applied_on.holiday_bump if self.applied_on
      @history_array = @history_array.reject{|h| h[:date] < applied_on_date}      
      return @history_array
    end
    
    def payment_schedule
      return @schedule if @schedule
      raise ArgumentError "This takeover loan is missing takeover information"  unless (self.taken_over_on || self.taken_over_on_installment_number)
      # TODO this exception is raised because we need to respect the first payment date and subsequent dates have to be 
      # adjusted to jive with everything else.
      self.taken_over_on_installment_number = number_of_installments_before(self.taken_over_on) if self.taken_over_on
      #store original values
      _amount = amount
      _disbursal_date = disbursal_date
      _scheduled_disbursal_date = scheduled_disbursal_date
      _fp_date = scheduled_first_payment_date
      # recreate the original loan
      self.scheduled_first_payment_date = original_first_payment_date
      saved_amount = self.amount unless self.new?
      self.amount = original_amount
      self.disbursal_date = original_disbursal_date
      # generate the payments_schedule
      super
      # chop off what doesn't belong to us
      self.taken_over_on ||= @schedule.keys.sort[(self.taken_over_on_installment_number) - 1]
      last_date = @schedule.reject{|k,v| k > self.taken_over_on}.keys.max
      total = @schedule[last_date][:total_balance]
      self.amount = saved_amount || @schedule[last_date][:balance].ceil
      @schedule = @schedule.reject{|k,v| k < last_date}
      # reset the original values
      self.disbursal_date = _disbursal_date
      self.scheduled_disbursal_date = _scheduled_disbursal_date
      self.scheduled_first_payment_date = _fp_date
      # adjust the first line of the payment_schedule
      dd = self.disbursal_date || self.scheduled_disbursal_date
      balance = saved_amount || @schedule[last_date][:balance]
      @schedule.delete(@schedule.keys.min)
      @schedule[dd] = {:principal => 0, :interest => 0, :total_principal => 0, :total_interest => 0, :balance => balance, :total => 0}

      # adjust all the dates
      adjusted_schedule = {}
      orig_dates = @schedule.keys.sort[1..-1]
      installment_dates.find_all{|d| d > last_date}.each_with_index do |d,i|
        adjusted_schedule[d] = payment_schedule[orig_dates[i]] if i < @schedule.count - 1
      end

      @schedule = {@schedule.keys.min => @schedule[@schedule.keys.min]} + adjusted_schedule
      # recreate the totals
      ti = tp = 0
      @schedule.keys.sort.each_with_index do |dt,idx|
        @schedule[dt][:total_interest] = ti += @schedule[dt][:interest]
        @schedule[dt][:principal] = idx == 0 ? 0 : (@schedule[@schedule.keys.sort[idx-1]][:balance] - @schedule[dt][:balance]).round(2)
        @schedule[dt][:total_principal] = tp += @schedule[dt][:principal]
        @schedule[dt][:total] = idx == 0 ? 0 : ti + tp
      end
      # do total_balance
      @schedule.each { |k,v| 
        v[:total_balance] = total - v[:total]
      }
      @schedule
    end
    
    def _show_original_cf
      #store original values
      _amount = amount
      _disbursal_date = disbursal_date
      _scheduled_disbursal_date = scheduled_disbursal_date
      _fp_date = scheduled_first_payment_date
      _original_amount = amount
      # recreate the original loan
      self.scheduled_first_payment_date = original_first_payment_date
      self.amount = original_amount
      self.disbursal_date = original_disbursal_date
      self.amount = original_amount
      # generate the payments_schedule
      clear_cache
      _show_cf
      self.disbursal_date = _disbursal_date
      self.scheduled_disbursal_date = _scheduled_disbursal_date
      self.scheduled_first_payment_date = _fp_date
      self.amount = _original_amount
    end

  end # Class.new
end # each

# pararth rounded with last principal less/more than usual
class RoundedAtLastInstallmentLoan < Loan
  def self.display_name
    "Rounded with last principal and interest adjusted"
  end

  def scheduled_principal_for_installment(number)
    raise "number out of range, got #{number}" if number < 1 or number > number_of_installments
    prin = (amount.to_f / number_of_installments)

    if number == number_of_installments
      ro_factor = prin - prin.send(loan_product.rounding_style)
      (prin.send(loan_product.rounding_style) + (number_of_installments - 1) * ro_factor).send(loan_product.rounding_style)
    else
      prin.send(loan_product.rounding_style)
    end
  end

  def scheduled_interest_for_installment(number)
    raise "number out of range, got #{number}" if number < 1 or number > number_of_installments
    total = (amount.to_f * (1 + interest_rate) / number_of_installments)

    if number == number_of_installments
      ro_factor = total - total.send(loan_product.rounding_style)
      (total.send(loan_product.rounding_style) - scheduled_principal_for_installment(number) + (number_of_installments - 1) * ro_factor).send(loan_product.rounding_style)
    else
      total.send(loan_product.rounding_style) - scheduled_principal_for_installment(number)
    end       
  end
end

# pararth rounded with last ineterst less/more than usual
class RoundedPrincipalAndInterestLoan < PararthRounded
  def self.display_name
    "Rounded with last interest adjusted"
  end
    
  def scheduled_principal_for_installment(number)
    raise "number out of range, got #{number}" if number < 1 or number > number_of_installments
    rounding_schedule[number][:principal].send(loan_product.rounding_style)
  end

  def scheduled_interest_for_installment(number)
    raise "number out of range, got #{number}" if number < 1 or number > number_of_installments
    if number == number_of_installments
      int_received_so_far = (1..(number-1)).map{|x| rounding_schedule[x][:interest]}.reduce(0){|s,x| s+=x}
      (amount * interest_rate - int_received_so_far).send(loan_product.rounding_style)
    else
      rounding_schedule[number][:interest].send(loan_product.rounding_style)
    end
  end
  
end

class EquatedWeeklyRoundedAdjustedLastPayment < EquatedWeekly
  # This loan product uses the original interest amounts as per the PMT funtion and adjusts principal accordingly.
  include ExcelFormula
  # property :purpose,  String

  def self.display_name
    "Equated Payments - rounded, adjusted in last payment "
  end

  def scheduled_principal_for_installment(number)
    # number unused in this implentation, subclasses may decide differently
    # therefor always supply number, so it works for all implementations
    raise "number out of range, got #{number} but max is #{number_of_installments}" if number < 0 or number > actual_number_of_installments
    return reducing_schedule[number][:principal_payable]
  end

  def scheduled_interest_for_installment(number)  # typically reimplemented in subclasses
    # number unused in this implentation, subclasses may decide differently
    # therefor always supply number, so it works for all implementations
    raise "number out of range, got #{number}" if number < 0 or number > actual_number_of_installments
    return reducing_schedule[number][:interest_payable]
  end

  def actual_number_of_installments
    reducing_schedule.count
  end

  def installment_dates
    insts = reducing_schedule.count
    return @_installment_dates if @_installment_dates
    if installment_frequency == :daily
      # we have to br careful that when we do a holiday bump, we do not get stuck in an endless loop
      ld = scheduled_first_payment_date - 1
      @_installment_dates = []
      (1..insts).each do |i|
        ld += 1
        if ld.cwday == weekly_off
          ld +=1
        end
        if ld.holiday_bump.cwday == weekly_off # endless loop
          ld.holiday_bump(:after)
        end
        @_installment_dates << ld
      end
      return @_installment_dates
    end
        
    ensure_meeting_day = false
    ensure_meeting_day = [:weekly, :biweekly].include?(installment_frequency)
    ensure_meeting_day = true if self.loan_product.loan_validations and self.loan_product.loan_validations.include?(:scheduled_dates_must_be_center_meeting_days)
    @_installment_dates = (0..(insts-1)).to_a.map {|x| shift_date_by_installments(scheduled_first_payment_date, x, ensure_meeting_day) }    
  end

  def equated_payment
    payment = pmt(interest_rate/get_divider, number_of_installments, amount, 0, 0)
    rnd = loan_product.rounding || 1
    actual_payment = (payment / rnd).send(loan_product.rounding_style) * rnd
  end

private
  def reducing_schedule
    return @rounded_schedule if @rounded_schedule
    @reducing_schedule = {}    
    balance = amount
    payment            = pmt(interest_rate/get_divider, number_of_installments, amount, 0, 0)
    1.upto(number_of_installments){|installment|
      @reducing_schedule[installment] = {}
      @reducing_schedule[installment][:interest_payable]  = ((balance * interest_rate) / get_divider)
      if installment == number_of_installments or balance < (payment - @reducing_schedule[installment][:interest_payable])
        @reducing_schedule[installment][:principal_payable] = balance
      else
        @reducing_schedule[installment][:principal_payable] = (payment - @reducing_schedule[installment][:interest_payable])
      end
      balance = balance - @reducing_schedule[installment][:principal_payable]
    }
    done = false
    i = 1
    @rounded_schedule = {}
    balance = amount
    actual_payment = equated_payment
    while not done
      @rounded_schedule[i] = {}
      @rounded_schedule[i][:interest_payable] = (i <= @reducing_schedule.count ? @reducing_schedule[i][:interest_payable] : 0).round(2)
      @rounded_schedule[i][:principal_payable] = [actual_payment - @rounded_schedule[i][:interest_payable], balance].min
      balance -= @rounded_schedule[i][:principal_payable]
      i += 1
      done = true if balance == 0 
    end
    return @rounded_schedule
  end

end

class EquatedWeeklyRoundedNewInterest < EquatedWeekly
  # This loan product recalculates interest based on the new balances after rounding.
  include ExcelFormula
  # property :purpose,  String

  def self.display_name
    "Reducing balance schedule with new interest (Equated Weekly)"
  end
  
  def scheduled_principal_for_installment(number)
    # number unused in this implentation, subclasses may decide differently
    # therefor always supply number, so it works for all implementations
    raise "number out of range, got #{number} but max is #{number_of_installments}" if number < 0 or number > number_of_installments
    return reducing_schedule[number][:principal_payable]
  end

  def scheduled_interest_for_installment(number)  # typically reimplemented in subclasses
    # number unused in this implentation, subclasses may decide differently
    # therefor always supply number, so it works for all implementations
    raise "number out of range, got #{number}" if number < 0 or number > number_of_installments
    return reducing_schedule[number][:interest_payable]
  end

  def equated_payment
    payment            = pmt(interest_rate/get_divider, number_of_installments, amount, 0, 0)
    rnd = loan_product.rounding || 1
    (payment / rnd).send(loan_product.rounding_style) * rnd
  end    
  
private
  def reducing_schedule
    return @reducing_schedule if @reducing_schedule
    @reducing_schedule = {}    
    balance = amount
    actual_payment = equated_payment
    1.upto(number_of_installments){|installment|
      @reducing_schedule[installment] = {}
      @reducing_schedule[installment][:interest_payable]  = ((balance * interest_rate) / get_divider)
      @reducing_schedule[installment][:principal_payable] = [(actual_payment - @reducing_schedule[installment][:interest_payable]), balance].min
      balance = balance - @reducing_schedule[installment][:principal_payable]
    }
    return @reducing_schedule
  end
  
  def get_divider
    case installment_frequency
    when :weekly
      52
    when :biweekly
      26
    when :fortnightly
      26
    when :monthly
      12
    when :daily
      365
    end    
  end
end

# always add new loan types here i.e. at last
