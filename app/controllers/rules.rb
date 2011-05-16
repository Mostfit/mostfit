class Rules < Application
  # provides :xml, :yaml, :js
  def index
    @rules = Rule.all
    display @rules
  end

  def show(id)
    @rule = Rule.get(id)
    raise NotFound unless @rule
    display @rule
  end

  def new
    only_provides :html
    @rule = Rule.new
    display @rule
  end

  def edit(id)
    only_provides :html
    @rule = Rule.get(id)
    raise NotFound unless @rule
    display @rule
  end

  def create(rule)
    rule = fix_conditions(rule)

    # Rule.new fails if on_action is an empty string; make it nil, so this will
    # be trapped by the validations later.
    rule[:on_action] = nil if rule[:on_action].empty?

    @rule = Rule.new(rule)
    if @rule.save
      redirect resource(@rule), :message => {:notice => "Rule was successfully created"}
    else
      message[:error] = "Rule failed to be created"
      render :new
    end
  end

  #TODO has to be fixed
  def update(id, rule)
    rule = fix_conditions(rule)
    @rule = Rule.get(id)
    raise NotFound unless @rule
    if @rule.update(rule)
       redirect resource(@rule)
    else
      display @rule, :edit
    end
  end

  def destroy(id)
    @rule = Rule.get(id)
    raise NotFound unless @rule
    if @rule.destroy
      redirect resource(:rules)
    else
      raise InternalServerError
    end
  end

  def keys(model)
    name, field, choices = Condition.get_field_choices_and_name(model)
    select_id = "select_#{params[:select_id].to_i+1}" if params[:select_id]

    if field==:select
      render(select(:name => name, :collection => choices, :class => "rules", :prompt => "select property", :id => select_id), :layout => false)
    else
      render(text_field(:name => name, :class => "rules"), :layout => false, :id => select_id)
    end
  end

  #only converts condition(hash) to condition(marshal objects) for DB storing
  def fix_conditions(rule)
    if rule[:precondition] == nil then rule[:precondition] = ""
    elsif rule[:precondition]["1"]["const_value"] == nil then rule[:precondition] = ""
    elsif rule[:precondition]["1"]["variable"]["1"]["complete"] == nil or rule[:precondition]["1"]["variable"]["1"]["complete"].length == 0 then rule[:precondition] = "" end
    rule[:precondition] = Marshal.dump(rule[:precondition])
    
    # the way that the rules UI behaves, there are multiple cases that could
    # mean that a user has not provided a condition for the rule
    if rule[:condition][:'1'][:const_value].nil? or
        rule[:condition][:'1'][:variable][:'1'][:complete].nil?

      rule[:condition] = nil
    end

    # Marshal.dump(nil) = "\004\b0", which would cause validations to assume
    # that condition is not empty.
    rule[:condition] = Marshal.dump(rule[:condition]) unless rule[:condition].nil?

    return rule
  end

  def get
    id = params[:id].to_i
    type = params[:type]
    if type != "precondition"
      type = "condition" #this step sanitizes "type", now this ensures that type is either "precondition" or "condition" and prevents XSS attacks since we will reflect back type to user
    end

    model, key_type = Condition.get_model(params[:for])
    condition_id = params[:condition_id]
    variable_id = params[:variable_id]
    return_only_models = params[:return_only_models]
    single_variable_mode = params[:single_variable_mode] #if this is 1, then we are in single veriable mode (this can be absent in which case, we assume more than one variables) - this ugly field is needed only for date since date - date should return int_selector while date - nil returns date_selector
    if (variable_id == nil) or (condition_id == nil) or (return_only_models == nil)
      return "problem 001"
    end
    condition_id = condition_id.to_i
    variable_id = variable_id.to_i
    if single_variable_mode == nil then single_variable_mode = 0 end
    single_variable_mode = single_variable_mode.to_i

    if model
      name, field, choices = Condition.get_field_choices_and_name(params[:for])
      name = "rule[#{type}][#{condition_id}][variable][#{variable_id}][keys][]"
      return render(select(:name => name, :id => "#{type}_select_#{id}", :class => "rules", :collection => choices), :layout => false)
    elsif return_only_models == "true"
      return "" #this is the situation when someone is when editing a variable
    else
      model = Kernel.const_get(params["prev_field".to_sym].singularize.camelcase)
      if model == nil
        return "nil1"
      end
      property = model.properties.find{|p| p.name.to_s==params[:for]} || model.relationships[params[:for]]
      name = "rule[#{type}][#{condition_id}][const_value]"
      type_name = "rule[#{type}][#{condition_id}][valuetype]" #will be either "string", "date" or "int"
      
      collection1 = [["less_than", "less than"], ["less_than_equal", "less than equal"], ["equal1", "equal"], ["greater_than", "greater than"], ["greater_than_equal", "greater than equal"], ["not1", "not equal"]]
      collection2 = [["equal2", "equal"], ["not2", "not equal"]]
      collection4 = [["+", "plus"], ["-", "minus"]]
      collection5 = [["-", "minus"]] #specifically for dates
      select1 = select(:id => "#{type}_selectcomparator_#{id}", :name => "rule[#{type}][#{condition_id}][comparator]", :prompt => "Choose operator", :collection => collection1)
      select2 = select(:id => "#{type}_selectcomparator_#{id}", :name => "rule[#{type}][#{condition_id}][comparator]", :prompt => "Choose operator", :collection => collection2)
      select3 = select(:id => "#{type}_selectmore_#{id+2}", :name => "rule[#{type}][#{condition_id}][linking_operator]", :prompt => "Add more #{type}", 
                       :collection => [["and", "and"], ["or", "or"]])
      select4 = select(:id => "#{type}_selectbinaryoperator_#{id}", :name => "rule[#{type}][#{condition_id}][binaryoperator]", :prompt => "Choose operator", :collection => collection4)
      select5 = select(:id => "#{type}_selectbinaryoperator_#{id}", :name => "rule[#{type}][#{condition_id}][binaryoperator]", :prompt => "Choose operator", :collection => collection5)
      next_textfield = text_field(:name => "rule[#{type}][#{condition_id}][variable][#{variable_id+1}][complete]", :value => "Variable 2", :class => "rules", :id => "#{type}_#{condition_id}_variable_#{variable_id+1}")

      if property.type==Date or property.type==DateTime
        hidden_valuetype = hidden_field(:id => "#{type}_hidden_#{id+1}", :name => type_name, 
                                        :value => "date")
        if(variable_id == 1)
          return select5 + next_textfield
        elsif single_variable_mode == 1
          return select1 + date_select(name , Date.today, :id => "#{type}_date_#{id+1}", :nullable => true) + hidden_valuetype+select3
        elsif(variable_id>1)
          return select1 + text_field(:id => "#{type}_textfield_#{id+1}", :name => name)+hidden_valuetype+select3
        end
    	elsif [DataMapper::Types::Serial, Integer].include?(property.type) or ['count', 'max', 'min', 'value'].include?(params[:for])
        hidden_valuetype = hidden_field(:id => "#{type}_hidden_#{id+1}", :name => type_name, 
                                        :value => "int")
        if(variable_id == 1)
          return select4+next_textfield
        else
          return select1+text_field(:id => "#{type}_textfield_#{id+1}", :name => name)+hidden_valuetype+select3
        end
      elsif Float == property.type
        hidden_valuetype = hidden_field(:id => "#{type}_hidden_#{id+1}", :name => type_name, 
                                        :value => "float")
        if(variable_id == 1)
          return select4+next_textfield
        else
          return select1+text_field(:id => "#{type}_textfield_#{id+1}", :name => name)+hidden_valuetype+select3
        end
      elsif [String, DataMapper::Types::Text].include?(property.type)
        return select2+text_field(:id => "#{type}_textfield_#{id+1}", :name => name)+select3
      elsif property.class==DataMapper::Associations::ManyToOne::Relationship
        return select2 + select(:id => "#{type}_selectvalue_#{id+1}", :name => name, :collection => property.parent_model.all, :value_method => :id, :text_method => :name, :prompt => "Choose #{property.name}") + select3        
      elsif property.type==DataMapper::Types::Boolean
        return select2+select(:id => "#{type}_selectboolean_#{id+1}", :name => name, 
                              :collection => [["true", "yes"], ["false", "no"]], :prompt => "Choose #{property.name}")+select3
      elsif property.type.class==Class
        return select2+text_field(:id => "#{type}_textfield_#{id+1}", :name => name)+select3
      end      
    end
  end  
end # Rules
