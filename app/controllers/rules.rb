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

    @rule = Rule.new(rule)
    if @rule.save
      redirect resource(@rule), :message => {:notice => "Rule was successfully created"}
    else
      message[:error] = "Rule failed to be created"
      render :new
    end
  end

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
		@rule.remove_rule
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

  def fix_conditions(rule)
    if rule[:precondition] == nil then rule[:precondition] = "" end
    rule[:condition] = Marshal.dump(rule[:condition])
    rule[:precondition] = Marshal.dump(rule[:precondition])
    return rule
  end

#  def fix_conditions(rule)
#    # fix till wee need multiple conditions
#    rule[:conditions] = [rule[:conditions]]
#    rule[:conditions].each_with_index do |condition, idx|
#      rule[:conditions][idx][:keys] = rule[:conditions][idx][:keys].join(".")
#    end
#    rule
#  end

  def get
		id = params[:id].to_i
    model, key_type = Condition.get_model(params[:for])
    condition_id = params[:condition_id]
		if model #field == :select
		#debugger
      name, field, choices = Condition.get_field_choices_and_name(params[:for])
      name = "rule[condition][#{condition_id}][keys][]"
			return render(select(:name => name, :id => "select_#{id}", :class => "rules", :collection => choices), :layout => false)
		else
			model = Kernel.const_get(params["prev_field".to_sym].singularize.camelcase)
			if model == nil
				return "nil1"
      end
	    property = model.properties.find{|p| p.name.to_s==params[:for]} || model.relationships[params[:for]]
      name = "rule[condition][#{condition_id}][value]"

			collection1 = [["less_than", "less than"], ["less_than_equal", "less than equal"], ["equal1", "equal to"], ["greater_than", "greater than"], ["greater_than_equal", "greater than equal"], ["not1", "not equal to"]]
			collection2 = [["equal2", "equal"], ["not2", "not equal"]]
      select1 = select(:id => "selectcomparator_#{id}", :name => "rule[condition][#{condition_id}][comparator]", :prompt => "Choose operator", :collection => collection1)
      select2 = select(:id => "selectcomparator_#{id}", :name => "rule[condition][#{condition_id}][comparator][]", :prompt => "Choose operator", :collection => collection2)
      select3 = select(:id => "selectmore_#{id+2}", :name => "rule[condition][#{condition_id}][linking_operator]", :prompt => "Add more condition", 
                       :collection => [["and", "and"], ["or", "or"]])

	    if property.type==Date or property.type==DateTime
		    return select1+date_select(name , Date.today, :id => "date_#{id+1}")+select3
    	elsif [DataMapper::Types::Serial, Integer, Float].include?(property.type)
	      return select1+text_field(:id => "textfield_#{id+1}", :name => name)+select3
    	elsif [String, DataMapper::Types::Text].include?(property.type)
	      return select2+text_field(:id => "textfield_#{id+1}", :name => name)+select3
  	  elsif property.class==DataMapper::Associations::ManyToOne::Relationship
        return select2+
          select(:id => "selectvalue_#{id+1}", :name => name, :collection => property.parent_model.all, :value_method => :id, :text_method => :name, :prompt => "Choose #{property.name}")+
          select3
          
	    elsif property.type==DataMapper::Types::Boolean
  	    return select2+select(:id => "selectboolean_#{id+1}", :name => name, 
                    :collection => [["true", "yes"], ["false", "no"]], :prompt => "Choose #{property.name}")+select3
	    elsif property.type.class==Class
	      return select2+text_field(:id => "textfield_#{id+1}", :name => name)+select3
      end
  
		end
  end
  
end # Rules
