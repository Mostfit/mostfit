class User
  include DataMapper::Resource

  before :destroy, :prevent_destroying_admin

  property :id,           Serial
  property :login,        String, :nullable => false
  property :created_at,   DateTime              
  property :updated_at,   DateTime
  property :active,       Boolean, :default => true, :nullable => false

  # permissions
  property :read_only_user,      Boolean, :default => false, :nullable => false  # read_only (duh!)
  property :data_entry_operator, Boolean, :default => false, :nullable => false  # can do some things
  property :mis_manager,         Boolean, :default => false, :nullable => false  # can do most things
  property :admin,               Boolean, :default => false, :nullable => false  # can do everything

  # it gets                                   
  #   - :password and :password_confirmation accessors
  #   - :crypted_password and :salt db columns        
  # from the mixin.
  validates_present :login
  validates_format :login, :with => /^[A-Za-z0-9_]+$/
  validates_length :login, :min => 3
  validates_is_unique :login
  validates_with_method :is_any_permission_granted

  has n, :payments_created, :child_key => [:created_by_user_id], :class_name => 'Payment'
  has n, :payments_deleted, :child_key => [:deleted_by_user_id], :class_name => 'Payment'
  has n, :audit_trail, :class_name => 'AuditTrail'


  def admin?
    self.admin || self.id == 1
  end
  def is_any_permission_granted
  read_only_user||data_entry_operator||mis_manager||admin
  end
 private
  def prevent_destroying_admin
    if id == 1
      errors.add(:login, "Cannot delete #{login} (the admin user).")
      throw :halt
    end                                                             
  end
end
