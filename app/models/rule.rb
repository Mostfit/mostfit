class Rule
  include DataMapper::Resource
  property :id,                  Serial
  property :name,                String,  :index => true
  property :model_name,          String,  :index => true
  property :permit,              Boolean, :index => true, :default => true
  property :on_action,           Enum[:create, :update, :save, :destroy], :index => true

  property :active,              Boolean, :default => false

  has n,   :conditions
  has n,   :pre_conditions, :model => Condition

  validates_present :name
  validates_present :model_name
  validates_present :permit
  validates_present :on_action
  validates_present :active
  validates_is_unique :name
  
  def atleast_one_conditio
    return [false, "there are no conditions"] if self.conditions.count==0
    return true
  end

end
