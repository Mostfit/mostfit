class Search
  include DateParser
  attr_accessor :models, :properties, :operators, :vals, :queries
  
  def initialize(hash)
    hash        = hash.collect{|k,v| {k.to_sym => v}}.inject({}){|s,x| s+=x}    
    @models, @properties, @operators, @vals = *prepare_hash(hash)
    @queries    = {}
  end
  
  def self.get_operators(property)
    if property.type==DataMapper::Associations::ManyToOne::Relationship
      return [["eql", "equal"], ["not", "not equal"]]
    elsif [DataMapper::Types::Serial, Integer, Float, DateTime, Date, Time].include?(property.type)
      return [["lt", "less than"], ["lte", "less than equal"], ["eql", "equal to"], ["gt", "greater than"], ["gte", "greater than equal"], ["not", "not equal to"]]
    elsif [DataMapper::Types::Text, String].include?(property.class)
      return [["eql", "equal"], ["like", "like"]]
    elsif [DataMapper::Types::Boolean].include?(property.class)
      return [["true", "true"], ["false", "false"]]
    elsif property.type.class==Class
      return [["eql", "equal"], ["not", "not equal"]]
    else
      return []
    end
  end

  def process
    property_to_relationship
    transform_enums
    prepare_queries if queries.length==0
    return chain_queries
  end

  private
  def chain_queries
    #No chaining
    return models.first.all(queries.values.first) if models.uniq.length==1
    #chaining
    objs = nil
    objs = models.first.all(queries[models.first])
    models.uniq[1..-1].each{|model|
      objs = objs.send(model.to_s.snake_case.pluralize, queries[model])
    }
    objs
  end

  def transform_enums
    #transform values to symbols if property is a flag map/enum
    properties.each_with_index{|p, idx| 
      prop = models[idx].properties.find{|x| x.name==p.to_sym} 
      if prop.type.name==""
        vals[idx] = prop.type.flag_map[vals[idx].to_i]
      end
    }
  end
  
  def prepare_queries
    # preparing queries
    models.each_with_index{|model, idx|
      queries[model]||= {}
      prop = properties[idx].to_sym.send(operators[idx].to_sym)
      if [Hash, Mash].include?(vals[idx].class) and property_type = model.properties.find{|x| x.name==prop.target}.type and [Date, DateTime].include?(property_type)
        vals[idx] = parse_date(vals[idx].collect{|k,v| {k.to_sym => v}}.inject({}){|s,x| s+=x})
        queries[model][prop] = vals[idx]
      elsif queries[model][prop]
        val = queries[model][prop]
        queries[model][prop] = []
        queries[model][prop].push(val)
      else
        queries[model][prop] = vals[idx]
      end

    }
  end

  def property_to_relationship
    #check if property here is actually a relationship ?
    models.each_with_index{|m, idx|
      if not m.properties.find{|x| x.name==properties[idx].to_sym} and m.relationships[properties[idx].to_sym]
        properties[idx]=m.relationships[properties[idx].to_sym].child_key.map{|x| x.name}[0]
      end
    }
  end

  def prepare_hash(hash)
    [prepare_models(hash[:model]), prepare_properties(hash[:property]), prepare_operators(hash[:operator]), prepare_vals(hash[:value])]
  end

  def prepare_models(models)
    models.to_a.collect{|x| Kernel.const_get(x[1].camelcase)}
  end
  
  def prepare_operators(operators)
    operators.to_a.collect{|x| x[1]}
  end
  
  def prepare_vals(vals)
      vals.values.map{|x| x.values.first} if hash[:value]
  end
  
  def prepare_properties(properties)
    properties.to_a.collect{|x| x[1]}
  end
end
