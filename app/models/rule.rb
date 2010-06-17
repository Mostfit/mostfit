class Rule
  include DataMapper::Resource
  property :id,                  Serial
  property :name,                String,  :index => true
  property :model,               String,  :index => true
  property :permit,              Boolean, :index => true, :default => true
  property :on,                  Enum[:create, :update, :save, :destroy], :index => true
  
  has n, :conditions,     :model => Predicate
  has n, :pre_conditions, :model => Predicate 
end
