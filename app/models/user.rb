class User
  include DataMapper::Resource

  before :destroy, :prevent_destroying_admin

  property :id,           Serial
  property :login,        String, :nullable => false
  property :created_at,   DateTime              
  property :updated_at,   DateTime
  property :active,       Boolean, :default => true, :nullable => false

  # permissions
  ROLES = [:data_entry, :mis_manager, :admin, :read_only]
  property :role, Enum.send('[]', *ROLES), :nullable => false

  # it gets                                   
  #   - :password and :password_confirmation accessors
  #   - :crypted_password and :salt db columns        
  # from the mixin.
  validates_present :login
  validates_format :login, :with => /^[A-Za-z0-9_]+$/
  validates_length :login, :min => 3
  validates_is_unique :login


  has n, :payments_created, :child_key => [:created_by_user_id], :model => 'Payment'
  has n, :payments_deleted, :child_key => [:deleted_by_user_id], :model => 'Payment'
  has n, :audit_trail, :model => 'AuditTrail'

  def self.roles
    roles = []
    ROLES.each_with_index{|v, idx|
      roles << [v, v.to_s.gsub('_', ' ').capitalize]
    }
    roles
  end
  
  def crud_rights
    Misfit::Config.crud_rights[role]
  end

  def access_rights
    Misfit::Config.access_rights[role]
  end

  def can_access?(controller, action)
    return true if role == :admin
    r = (access_rights[action.to_s.to_sym] or access_rights[:all])
    return false if r.nil?
    r.include?(controller.to_sym)
  end

  def can_manage?(model)
    return true if role == :admin
    crud_rights.values.inject([]){|a,b| a + b}.uniq.include?(model)
  end
  

  def method_missing(name, params)
    if x = /can_\w+\?/.match(name.to_s)
      debugger
      return true if role == :admin
      function = x[0].split("_")[1].gsub("?","").to_sym # wtf happened to $1?!?!?
      puts function
      raise NoMethodError if not ([:edit, :update, :create, :new, :delete, :destroy].include?(function))
      model = params
      r = (crud_rights[function] or crud_rights[:all])
      return false if r.nil?
      r.include?(model)
    else
      raise NoMethodError
    end
  end

 private
  def prevent_destroying_admin
    if id == 1
      errors.add(:login, "Cannot delete #{login} (the admin user).")
      throw :halt
    end                                                             
  end
end
