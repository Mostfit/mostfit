# dont call save or update or anything on this method directly!!
# this class is managed by the loan, and should be completely managed by it.

class Payment
  include DataMapper::Resource

  attr_writer :total  # just to be used in the form
  
  property :id,             Serial
  property :principal,      Integer, :nullable => false, :default => 0
  property :interest,       Integer, :nullable => false, :default => 0
  property :received_on,    Date,    :nullable => false
  property :created_at,     DateTime
  property :deleted_at,     ParanoidDateTime

  belongs_to :loan
  belongs_to :created_by,  :child_key => [:created_by_user_id],   :class_name => 'User'
  belongs_to :received_by, :child_key => [:received_by_staff_id], :class_name => 'StaffMember'
  belongs_to :deleted_by,  :child_key => [:deleted_by_user_id],   :class_name => 'User'

  validates_present     :loan, :created_by, :received_by
  validates_with_method :only_take_payments_on_disbursed_loans?
  validates_with_method :created_by,  :method => :created_by_active_user?
  validates_with_method :received_by, :method => :received_by_active_staff_member?
  validates_with_method :deleted_by,  :method => :properly_deleted?
  validates_with_method :deleted_at,  :method => :properly_deleted?
  validates_with_method :principal,   :method => :not_paying_too_much_principal?
  validates_with_method :total,       :method => :not_paying_too_much_in_total?
  validates_with_method :received_on, :method => :not_received_in_the_future?
  validates_with_method :received_on, :method => :not_received_before_loan_is_disbursed?

  def total
    principal + interest
  end

  private
  def created_by_active_user?
    return true if created_by and created_by.active
    [false, "Payments can only be created if an active user is supplied"]
  end
  def received_by_active_staff_member?
    return true if received_by and received_by.active
    [false, "receiving staff member is currently not active"]
  end
  def properly_deleted?
    return true if (deleted_by and deleted_at) or (!deleted_by and !deleted_at)
    [false, "deleted_by and deleted_at properties have to be (un)set together"]
  end
  def not_paying_too_much_principal?
    if new_record?  # do not do this check on updates, it will count itself double
      a = loan.payments_hash[loan.payments_hash.keys.max]
      if ((a and a[:principal_received_so_far]) ? a[:principal_received_so_far] : 0) + principal > loan.amount
        return [false, "principal is more than the loans outstanding principal"]
      end
    end
    true
  end
  def not_paying_too_much_in_total?
    if new_record?  # do not do this check on updates, it will count itself double
      a = loan.payments_hash[loan.payments_hash.keys.max]
      new_total = ((a and a[:total_received_so_far]) ? a[:total_received_so_far] : 0) + total
      if new_total > loan.total_to_be_received
        return [false, "total is more than the loans outstanding total"]
      end
    end
    true
  end
  def only_take_payments_on_disbursed_loans?
    return true if loan.status == :outstanding
    [false, "payments cannot be made on loans that are written off, repaid or not (yet) disbursed"]
  end
  def not_received_in_the_future?
    return true if received_on <= Date.today
    [false, "payments cannot be received in the future"]
  end
  def not_received_before_loan_is_disbursed?
    return true if loan.disbursal_date.blank? ? false :  loan.disbursal_date <= received_on
    [false, "payments cannot be received before the loan is disbursed"]
  end
end
