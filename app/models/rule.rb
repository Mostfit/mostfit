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


  #
  # This probably doesn't happen too often, but.. Ouch...
  #
  after :destroy do
    h = {:name => @name, :model_name => @model_name}
    #puts "Removed Rule"
    Mostfit::Business::Rules.remove_rule h
    FileUtils.touch(File.join(Merb.root, "tmp", "restart.txt"))
  end

  after :update do
    h = {:name => @name, :model_name => @model_name}
    #puts "Removed Rule"
    Mostfit::Business::Rules.remove_rule h
    self.apply_rule #remove and re-apply rule
    FileUtils.touch(File.join(Merb.root, "tmp", "restart.txt"))
  end

  after :create do
    # create tmp/ if it does not exist
    FileUtils.mkdir_p(File.join(Merb.root, 'tmp'))

    FileUtils.touch(File.join(Merb.root, "tmp", "restart.txt"))
  end


  # On creating new rules occassionally I got a validation error "nil" which I'm assuming
  # originates here, would be nice to give a reason for the failure though I couldn't quite
  # figure out what it is (I think it's related to the Condition model somehow.)
  def apply_rule
    # can't go ahead without a condition
    return false unless condition

    # all attributes except id need to be in rules hash
    h = attributes.tap{|attr| attr.delete(:id)}

    # If apply_rule raises a runtime error, we simply cause the validation to
    # fail (return 'false').
    Mostfit::Business::Rules.apply_rule(h) rescue false
  end
end
