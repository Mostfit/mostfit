class Rule
  include DataMapper::Resource
  property :id,                  Serial
  property :name,                String, :min => 1, :index => true
  property :model_name,          String,  :index => true
  property :permit,              Boolean, :index => true, :default => true
  property :on_action,           Enum[:create, :update, :save, :destroy], :index => true

  property :active,              Boolean, :default => false

  property :condition,		 Text, :length => 5000
  property :precondition,	 Text

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

  def apply_rule
		puts "Applying Rule #{@name}"
    puts self.condition
    h = {:name => @name, :on_action => @on_action, :model_name => @model_name, 
	    :permit => @permit, :condition => @condition, :precondition => @precondition}
    if h[:condition] == nil
      puts "condition is nil"
      debugger
      return false
    end
		Mostfit::Business::Rules.apply_rule h
  end

  def remove_rule
 		h = {:name => @name, :model_name => @model_name}
	  Mostfot::Business::Rules.remove_rule h
	end
  
#  def atleast_one_condition
#    return [false, "there are no conditions"] if self.conditions.count==0
#    return true
#  end

end
