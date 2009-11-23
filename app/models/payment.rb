# dont call save or update or anything on this method directly!!
# this class is managed by the loan, and should be completely managed by it.

class Payment
  include DataMapper::Resource
  before :valid?, :parse_dates
  # before :valid?, :add_loan_product_validations
  # after :valid?, :after_valid
  attr_writer :total  # just to be used in the form
  
  property :id,                 Serial
  property :amount,             Integer, :nullable => false, :index => true
  property :type,               Enum[:principal, :interest, :fees], :index => true
  property :received_on,        Date,    :nullable => false, :index => true
  property :deleted_by_user_id, Integer, :nullable => true, :index => true
  property :created_at,         DateTime,:nullable => false, :default => Time.now, :index => true
  property :deleted_at,         ParanoidDateTime, :nullable => true, :index => true

  belongs_to :loan
  belongs_to :created_by,  :child_key => [:created_by_user_id],   :model => 'User'
  belongs_to :received_by, :child_key => [:received_by_staff_id], :model => 'StaffMember'
  belongs_to :deleted_by,  :child_key => [:deleted_by_user_id],   :model => 'User'


  validates_present     :loan, :created_by, :received_by
  validates_with_method :only_take_payments_on_disbursed_loans?, :if => Proc.new{|p| (p.type == :principal or p.type == :interest)}
  validates_with_method :created_by,  :method => :created_by_active_user?
  validates_with_method :received_by, :method => :received_by_active_staff_member?
  validates_with_method :deleted_by,  :method => :properly_deleted?
  validates_with_method :deleted_at,  :method => :properly_deleted?
#  validates_with_method :not_paying_too_much?
#  validates_with_method :received_on, :method => :not_received_in_the_future?, :unless => Proc.new{|t| Merb.env=="test"}
  validates_with_method :received_on, :method => :not_received_before_loan_is_disbursed?, :if => Proc.new{|p| (p.type == :principal or p.type == :interest)}
#  validates_with_method :principal,   :method => :is_positive?

  def self.from_csv(row, headers, loans)
    obj = new(:received_by_staff_id => StaffMember.first(:name => row[headers[:received_by_staff]]).id, :loan_id => loans[row[headers[:loan_serial_number]]].id, 
              :amount => row[headers[:principal]], :type => :principal, :received_on => Date.parse(row[headers[:received_on]]), 
              :created_by_user_id => User.first.id)
    obj = new(:received_by_staff_id => StaffMember.first(:name => row[headers[:received_by_staff]]).id, :loan_id => loans[row[headers[:loan_serial_number]]].id, 
              :amount => row[headers[:interest]], :type => :interest, :received_on => Date.parse(row[headers[:received_on]]), 
              :created_by_user_id => User.first.id)
    [obj.save, obj]
  end


  def total
    amount
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

  def is_same_product
    true
  end

  def after_valid
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
  def only_take_payments_on_disbursed_loans?
#    debugger
    return true if loan.get_status(received_on) == :outstanding
    [false, "Payments cannot be made on loans that are written off, repaid or not (yet) disbursed. This loan is #{loan.get_status(received_on)}"]
  end
  def not_received_in_the_future?
    return true if received_on <= Date.today
    [false, "Payments cannot be received in the future"]
  end
  def not_received_before_loan_is_disbursed?
    return true if loan.disbursal_date.blank? ? false : loan.disbursal_date <= received_on
    [false, "Payments cannot be received before the loan is disbursed"]
  end
  def not_paying_too_much_principal?
    return true unless type == :principal
    if new?  # do not do this check on updates, it will count itself double
      a = loan.payments_hash[loan.payments_hash.keys.max]
      if (((not a.blank?) and a[:total_principal]) ? a[:total_principal] : 0) + amount > loan.amount
        return [false, "Principal is more than the loans outstanding principal"]
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

  def principal_is_positive?
    return true if principal.blank? ? true : principal >= 0
    [false, "Principal cannot be less than zero"]
  end
  def interest_is_positive?
    return true if interest.blank? ? true : interest >= 0
    [false, "Interest cannot be less than zero"]
  end
  def total_is_positive?
    return true if total.blank? ? true : total >= 0
    [false, "Total cannot be less than zero"]
  end
end
