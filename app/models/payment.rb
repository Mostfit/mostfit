# dont call save or update or anything on this method directly!!
# this class is managed by the loan, and should be completely managed by it.

class Payment
  include DataMapper::Resource

  attr_writer :total  # just to be used in the form
  
  property :id,             Serial
  property :principal,      Integer, :nullable => false
  property :interest,       Integer, :nullable => false
  property :received_on,    Date,    :nullable => false
  property :created_at,     DateTime
  property :deleted_at,     ParanoidDateTime

  belongs_to :loan
  belongs_to :created_by,  :class_name => 'User'
  belongs_to :received_by, :child_key => [:received_by_staff_id], :class_name => 'StaffMember'
  belongs_to :deleted_by,  :child_key => [:deleted_by_user_id],   :class_name => 'User'

  validates_present :loan_id, :user_id, :received_by_staff_id  # it seems better to validate on the column name
  validates_with_method :properly_deleted?
  validates_with_method :principal, :not_paying_too_much_principal?
  validates_with_method :total, :not_paying_too_much_in_total?
  validates_with_method :received_on, :not_received_in_the_future?
  validates_with_method :received_on, :not_received_before_loan_is_disbursed?
  validates_with_method :received_by, :received_by_active_staff_member?

  def total
    (principal and interest) ? principal + interest : nil
  end

  private
  def properly_deleted?
    return true if (self.deleted_by and self.deleted_at) or (!self.deleted_by and !self.deleted_at)
    [false, "deleted_by and deleted_at properties have to be (un)set together"]
  end
  def not_paying_too_much_principal?
    if new_record?  # do not do this check on updates, it will count itself double
      p = self.loan.payments_hash[self.loan.payments_hash.keys.max]
      if (p ? p[:principal_received_so_far] : 0) + self.principal > self.loan.amount
        return [false, "principal is more than the loans outstanding principal"]
      end
    end
    true
  end
  def not_paying_too_much_in_total?
    if new_record?  # do not do this check on updates, it will count itself double
      p = self.loan.payments_hash[self.loan.payments_hash.keys.max]
      if (p ? p[:total_received_so_far] : 0) + self.total > self.loan.total_to_be_received
        return [false, "total is more than the loans outstanding total"]
      end
    end
    true
  end
  def not_received_in_the_future?
    return true if self.received_on <= Date.today
    [false, "payments cannot be received in the future"]
  end
  def not_received_before_loan_is_disbursed?
    return true if not self.loan.disbursal_date.blank? and self.received_on >= self.loan.disbursal_date
    [false, "payments cannot be received before the loan is disbursed"]
  end
  def received_by_active_staff_member?
    return true unless StaffMember.first(:id => self.received_by_staff_id, :active => true).blank?
    [false, "receiving staff member is currently not active"]
  end
end
