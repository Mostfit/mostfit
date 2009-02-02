class Payment
  include DataMapper::Resource
  
  property :id,             Serial
  property :principal,      Integer, :nullable => false
  property :interest,       Integer, :nullable => false
  property :total,          Integer, :nullable => false  # do we need the this field (for clever sql queries)?
  property :received_on,    Date,    :nullable => false
  property :created_at,     DateTime
  property :deleted_at,     ParanoidDateTime

  belongs_to :loan
  belongs_to :created_by,  :class_name => 'User'
  belongs_to :received_by, :child_key => [:received_by_staff_id], :class_name => 'StaffMember'
  belongs_to :deleted_by,  :child_key => [:deleted_by_user_id],  :class_name => 'User'

  validates_present :loan_id, :created_by, :received_by
  validates_with_method :properly_deleted?
  validates_with_method :total, :correct_total?
  # payment principa/interest/total not more then loan
  # received on cannot be in the future
  # received_by has to point an active staff member

  private
  def properly_deleted?
    return true if (self.deleted_by and self.deleted_at) or (!self.deleted_by and !self.deleted_at)
    [false, "deleted_by and deleted_at properties have to be (un)set together"]
  end

  def correct_total?
    return true if self.total == self.principal + self.interest
    [false, "the sum of principal and interest should equal the total"]
  end
end
