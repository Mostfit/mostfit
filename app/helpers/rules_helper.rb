module Merb
  module RulesHelper

    def get_model_for(name, ancestor = nil)
      return Kernel.const_get(name.singularize.camelcase)
    rescue
      klass = Kernel.const_get(ancestor.singularize.camelcase)
      if association = klass.relationships[name]
        return association.parent_model
      end
    end

    def get_choices_for(model)
      (model.properties.map{|x| x.name.to_s} + model.relationships.keys)
    end
  end
end # Merb
