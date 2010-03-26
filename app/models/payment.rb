# dont call save or update or anything on this method directly!!
# this class is managed by the loan, and should be completely managed by it.

class Payment
  include DataMapper::Resource
  before :valid?, :parse_dates
  before :valid?, :check_client
  # before :valid?, :add_loan_product_validations
  # after :valid?, :after_valid
  before :valid?, :check_client
  attr_writer :total  # just to be used in the form

  PAYMENT_TYPES = [:principal, :interest, :fees]
  
  property :id,                  Serial
  property :amount,              Integer, :nullable => false, :index => true
  property :type,                Enum.send('[]',*PAYMENT_TYPES), :index => true
  property :comment,             String, :length => 50
  property :received_on,         Date,    :nullable => false, :index => true
  property :deleted_by_user_id,  Integer, :nullable => true, :index => true
  property :created_at,          DateTime,:nullable => false, :default => Time.now, :index => true
  property :deleted_at,          ParanoidDateTime, :nullable => true, :index => true
  property :created_by_user_id,  Integer, :nullable => false, :index => true
  property :verified_by_user_id, Integer, :nullable => true, :index => true
  property :loan_id,             Integer, :nullable => true, :index => true
  property :client_id,           Integer, :nullable => true, :index => true

  belongs_to :loan, :nullable => true
  belongs_to :client
  belongs_to :created_by,  :child_key => [:created_by_user_id],   :model => 'User'
  belongs_to :received_by, :child_key => [:received_by_staff_id], :model => 'StaffMember'
  belongs_to :deleted_by,  :child_key => [:deleted_by_user_id],   :model => 'User'


  validates_present     :created_by, :received_by
  validates_with_method :loan_or_client_present?
  validates_with_method :only_take_payments_on_disbursed_loans?, :if => Proc.new{|p| (p.type == :principal or p.type == :interest)}
  validates_with_method :created_by,  :method => :created_by_active_user?
  validates_with_method :received_by, :method => :received_by_active_staff_member?
  validates_with_method :deleted_by,  :method => :properly_deleted?
  validates_with_method :deleted_at,  :method => :properly_deleted?
  validates_with_method :not_approved, :method => :not_approved, :on => [:destroy]
#  validates_with_method :received_on, :method => :not_received_in_the_future?, :unless => Proc.new{|t| Merb.env=="test"}
  validates_with_method :received_on, :method => :not_received_before_loan_is_disbursed?, :if => Proc.new{|p| (p.type == :principal or p.type == :interest)}
  validates_with_method :principal,   :method => :is_positive?
  
  def self.from_csv(row, headers, loans)
    obj = new(:received_by => StaffMember.first(:name => row[headers[:received_by_staff]]), :loan => loans[row[headers[:loan_serial_number]]], 
              :amount => row[headers[:principal]], :type => :principal, :received_on => Date.parse(row[headers[:received_on]]), 
              :created_by => User.first)
    obj = new(:received_by => StaffMember.first(:name => row[headers[:received_by_staff]]), :loan => loans[row[headers[:loan_serial_number]]], 
              :amount => row[headers[:interest]], :type => :interest, :received_on => Date.parse(row[headers[:received_on]]), 
              :created_by => User.first)
    [obj.save, obj]
  end


  def total
    amount
  end

  def self.types
    PAYMENT_TYPES
  end

  private
  include DateParser  # mixin for the hook "before: valid?, :parse_dates"
  include Misfit::PaymentValidators
  def add_loan_product_validations
    return unless loan and loan.loan_product
    # THIS WORKS
#    clause = eval "Proc.new{|t| t.loan.loan_product.id == 1}"
    #Payment.add_validator_to_context({:context => :default}, 
    #                                 loan.loan_product.payment_validations, DataMapper::Validate::MethodValidator)
    Payment.add_validator_to_context({:context => :default, :if => eval("Proc.new{|t| t.loan.loan_product.id == #{loan.loan_product.id}}")}, loan.loan_product.payment_validations,DataMapper::Validate::MethodValidator)
  end

  def check_client
    self.client = loan.client if loan and not client
  end

  def is_same_product
    true
  end

  def after_valid
  end

  def loan_or_client_present?
    return [false, "Needs to belong either to a loan or to a client"] unless (loan or client)
    return true
  end

  def created_by_active_user?
    return true if created_by and created_by.active
    [false, "Payments can only be created if an active user is supplied"]
  end
  def received_by_active_staff_member?
    return true if received_by and received_by.active
    [false, "Receiving staff member is currently not active"]
  end
  def properly_deleted?
    return true if (deleted_by and deleted_at) or (!deleted_by and !deleted_at)
    [false, "deleted_by and deleted_at properties have to be (un)set together"]
  end

  def allowed_edit?
    orig = self.class.get(self.id)
    if verified_by_user_id and verified_by_user_id>0 and orig.verified_by_user_id and orig.verified_by_user_id>0
      return [false, "Cannot delete or edit an approved payment"]
    else
      return true
    end
  end

  def only_take_payments_on_disbursed_loans?
    if loan
      return true if loan.get_status(received_on) == :outstanding
      [false, "Payments cannot be made on loans that are written off, repaid or not (yet) disbursed. This loan is #{loan.get_status(received_on)}"]
    end
  end
  def not_received_in_the_future?
    return true if received_on <= Date.today
    [false, "Payments cannot be received in the future"]
  end
  def not_received_before_loan_is_disbursed?
    if loan
      return [false, "Payments cannot be received before the loan is disbursed"] if loan.disbursal_date.blank?
      return [false, "Payments cannot be received before the loan disbursal date"] if loan.disbursal_date > received_on
      return true
    end
  end
  def not_paying_too_much?
    if new?  # do not do this check on updates, it will count itself double
      if type == :principal
        a = loan.actual_outstanding_principal_on(received_on)
      elsif type == :interest
        a = loan.actual_outstanding_interest_on(received_on)
      elsif type == :fees
        a = loan.total_fees_payable_on(received_on) if loan
        a = client.total_fees_payable_on(received_on) if client and not loan
      end
      if (not a.blank?) and amount > a
        return [false, "#{type} is more than the total #{type} due"]
      end
    end
    true
  end
  def not_paying_too_much_in_total?
    if new?   # do not do this check on updates, it will count itself double
      a = loan.actual_outstanding_total_on(received_on)
      if total > a
        return [false, "Total is more than the loans outstanding total"]
      end
    end
    true
  end

  def is_positive?
    return true if amount.blank? ? true : amount >= 0
    [false, "Amount cannot be less than zero"]
  end
end
