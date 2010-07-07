class Rule
  include DataMapper::Resource
  property :id,                  Serial
  property :name,                String,  :index => true
  property :model_name,          String,  :index => true
  property :permit,              Boolean, :index => true, :default => true
  property :on_action,           Enum[:create, :update, :save, :destroy], :index => true
  property :condition,           String
  property :pre_conditions,      String
end
