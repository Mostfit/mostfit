class User
  include DataMapper::Resource

  before :destroy, :prevent_destroying_admin

  property :id,           Serial
  property :login,        String, :nullable => false
  property :created_at,   DateTime              
  property :updated_at,   DateTime
  property :active,       Boolean, :default => true, :nullable => false

  # permissions
  
  property :data_entry_operator, Boolean, :default => false, :nullable => false # can do some things
  property :admin, Boolean, :default => false, :nullable => false               # can do everything
  property :mis_manager, Boolean, :default => false, :nullable => false         # can do most things
  property :read_only_user, Boolean, :default => false, :nullable => false      # read_only (duh!)

  

  # it gets                                   
  #   - :password and :password_confirmation accessors
  #   - :crypted_password and :salt db columns        
  # from the mixin.

  validates_format :login, :with => /^[A-Za-z0-9_]+$/
  validates_length :login, :min => 3
  validates_is_unique :login

  has n, :payments_created, :child_key => [:created_by_user_id], :class_name => 'Payment'
  has n, :payments_deleted, :child_key => [:deleted_by_user_id], :class_name => 'Payment'
  has n, :audit_trail, :class_name => 'AuditTrail'

  def can_write(object)
    self.admin || self.mis_manager || ((object.class.to_s == 'Loan' || object.class.to_s == 'Payment') && self.data_entry_operator)
  end

  def admin?
    self.admin || self.id == 1
  end

  private
  def prevent_destroying_admin
    if id == 1
      errors.add(:login, "Cannot delete #{login} (the admin user).")
      throw :halt
    end                                                             
  end
end
