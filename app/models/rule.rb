class Rule
  include DataMapper::Resource
  property :id,                  Serial
  property :name,                String, :nullable => false, :min => 1, :index => true
  property :model_name,          String, :nullable => false, :min => 1, :index => true
  property :permit,              Boolean, :index => true, :default => true
  property :on_action,           Enum[:create, :update, :save, :destroy], :nullable => false, :index => true

  property :active,              Boolean, :default => false

  property :condition,		 Text, :length => 5000, :lazy => false
  property :precondition,	 Text, :length => 5000, :lazy => false

#delete this
# has n,   :conditions
# has n,   :pre_conditions, :model => Condition, :is_rule => false

  validates_present :name
  validates_present :model_name
  validates_present :permit
  validates_present :on_action
  validates_present :active
  validates_present :condition #precondition can be null (condition should not be null)
  validates_is_unique :name
  validates_with_method :apply_rule

  after :destroy do
    h = {:name => @name, :model_name => @model_name}
    #puts "Removed Rule"
    Mostfit::Business::Rules.remove_rule h
  end

  after :update do
    h = {:name => @name, :model_name => @model_name}
    #puts "Removed Rule"
    Mostfit::Business::Rules.remove_rule h
    self.apply_rule #remove and re-apply rule
  end

  def apply_rule
    #puts "Applying Rule #{@name}"
    h = {:name => @name, :on_action => @on_action, :model_name => @model_name, 
	    :permit => @permit, :condition => @condition, :precondition => @precondition}
    if h[:condition] == nil
      return [false, "no condition given"]
    end
    Mostfit::Business::Rules.apply_rule h
  end

end
