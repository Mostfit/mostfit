class Condition
  COMPARATORS = {:less_than => :<, :less_than_equal => :<=, :equal => :==, :greater_than => :>, :greater_than_equal => :>=}
  
  include DataMapper::Resource  
  property :id,          Serial
  property :keys,        String
  property :comparator,  Enum.send('[]', *[:<, :<=, :==, :>, :>=])
  property :value,       String
  property :is_rule,     Boolean, :default => true  

  belongs_to :rule

  validates_present :keys
  validates_present :comparator
  validates_present :value
  validates_present :rule

  def self.get_model(model_name)
    model, key_type = nil, :secondary
    if Mostfit::Business::Rules.all_models.index(model_name.to_sym)
      model = Kernel.const_get(model_name.camelcase)
      key_type = :primary
    elsif Mostfit::Business::Rules.all_models.index(model_name.singularize.to_sym)
      model = Kernel.const_get(model_name.singularize.camelcase)      
    end
    [model, key_type]
  end

  def self.get_choices(model, key_type)
    if key_type==:primary
      (model.properties.map{|x| x.name.to_s} + model.relationships.keys)
    else
      ['count', 'value'] + model.relationships.keys
    end
  end

  def self.get_field_choices_and_name(key_name)
    model, key_type = get_model(key_name)
    choices         = get_choices(model, key_type) if model and key_type

    if model
      field   = :select
      name  = "rule[conditions][keys][]"
#    elsif ['count', 'max', 'min', 'value'].include?(key_name)     
#      field = :select
#      choices = ['<=', '>=', '=']
#      name  = "rule[conditions][comparator]"
#    elsif ['<=', '>=', '='].include?(key_name)
#      field = :text_field
#      name  = "rule[conditions][value]"
    end    
    return [name, field, choices]
  end
end


    # if Mostfit::Business::Rules.all_models.index(model.to_sym)
    #   model = Kernel.const_get(model.camelcase)
    #   choices = (model.properties.map{|x| x.name.to_s} + model.relationships.keys)
    #   field   = :select
    #   name  = "rule[conditions][keys][]"
    # elsif Mostfit::Business::Rules.all_models.index(model.singularize.to_sym)
    #   # it is an array. Choices are count, max, min etc
    #   choices = ['count', 'value']
    #   model = Kernel.const_get(model.singularize.camelcase)      
    #   choices += model.relationships.keys
    #   field   = :select
    #   name  = "rule[conditions][keys][]"
    # elsif ['count', 'max', 'min', 'value'].include?(model)      
    #   field = :select
    #   choices = ['<=', '>=', '=']
    #   name  = "rule[conditions][comparator]"
    # elsif ['<=', '>=', '='].include?(model)
    #   field = :text_field
    #   name  = "rule[conditions][value]"
    # end
