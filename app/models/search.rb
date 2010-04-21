class Search
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

  def self.process(hash)
    models     = hash[:model].to_a.collect{|x| Kernel.const_get(x[1].camelcase)}
    properties = hash[:property].to_a.collect{|x| x[1]}
    operators  = hash[:operator].to_a.collect{|x| x[1]}
    vals       = hash[:value].values.map{|x| x.values.first}

    #check if property here is actually a relationship ?
    models.each_with_index{|m, idx|
      if not m.properties.find{|x| x.name==properties[idx].to_sym} and m.relationships[properties[idx].to_sym]
        properties[idx]=m.relationships[properties[idx].to_sym].child_key.map{|x| x.name}[0]
      end
    }

    #transform values to symbols if property is a flag map/enum
    properties.each_with_index{|p, idx| 
      prop = models[idx].properties.find{|x| x.name==p.to_sym} 
      if prop.type.name==""
        vals[idx] = prop.type.flag_map[vals[idx].to_i]
      end
    }
    queries    = {}
    models.each_with_index{|model, idx|
      queries[model]||= {}
      prop = properties[idx].to_sym.send(operators[idx].to_sym)
      if queries[model][prop]
        queries[model][prop] << vals[idx]
      else
        queries[model][prop] = [vals[idx]]
      end
    }
    return self.chain_queries(models.uniq, queries)
  end

  private
  def self.chain_queries(models, queries)
    #No chaining
    return models.first.all(queries.values.first) if models.uniq.length==1
    #chaining
    objs = nil
    objs = models.first.all(queries[models.first])
    models[1..-1].each{|model|
      objs = objs.send(model.to_s.snake_case.pluralize, queries[model])
    }
    objs
  end
end
