class User
  include DataMapper::Resource

  before :destroy, :prevent_destroying_admin
  after  :save,    :set_staff_member

  property :id,           Serial
  property :login,        String, :nullable => false
  property :created_at,   DateTime              
  property :updated_at,   DateTime
  property :active,       Boolean, :default => true, :nullable => false

  # permissions
  # to add to this, only add at the back of the array
  ROLES = [:data_entry, :mis_manager, :admin, :read_only, :staff_member]
  property :role, Enum.send('[]', *ROLES), :nullable => false

  # it gets                                   
  #   - :password and :password_confirmation accessors
  #   - :crypted_password and :salt db columns        
  # from the mixin.
  validates_present :login
  validates_format :login, :with => /^[A-Za-z0-9_]+$/
  validates_length :login, :min => 3
  validates_is_unique :login
  validates_length :password, :min => 6  
  has 1, :staff_member


  has n, :payments_created, :child_key => [:created_by_user_id], :model => 'Payment'
  has n, :payments_deleted, :child_key => [:deleted_by_user_id], :model => 'Payment'
  has n, :audit_trail, :model => 'AuditTrail'
  
  def set_staff_member
    if self.staff_member
      staff          = StaffMember.get(self.staff_member.id)
      staff.user_id  = self.id
      staff.save
    end
  end

  def name
    login
  end

  def self.roles
    roles = []
    ROLES.each_with_index{|v, idx|
      roles << [v, v.to_s.gsub('_', ' ').capitalize]
    }
    roles
  end

  def admin?
    role == :admin
  end
  
  def crud_rights
    Misfit::Config.crud_rights[role]
  end

  def access_rights
    Misfit::Config.access_rights[role]
  end

  def can_access?(route, params = nil)
    return true if role == :admin
    return true if route[:controller] == "graph_data"
    controller = (route[:namespace] ? route[:namespace] + "/" : "" ) + route[:controller]
    model = route[:controller].singularize.to_sym
    action = route[:action]

    if route.has_key?(:id)
      return can_manage?(model, route[:id])
    end
    r = (access_rights[action.to_s.to_sym] or access_rights[:all])
    return false if r.nil?
    r.include?(controller.to_sym) or r.include?(controller.split("/")[0].to_sym)
  end

  def can_manage?(model, id = nil)
    return true if role == :admin
    return crud_rights.values.inject([]){|a,b| a + b}.uniq.include?(model.to_s.snake_case.to_sym)
  end

  def to_s
    login
  end

  def method_missing(name, params)
    if x = /can_\w+\?/.match(name.to_s)
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
