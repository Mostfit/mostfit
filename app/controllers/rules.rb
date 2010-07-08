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
    # fix till wee need multiple conditions
    rule[:conditions] = [rule[:conditions]]
    rule[:conditions].each_with_index do |condition, idx|
      rule[:conditions][idx][:keys] = rule[:conditions][idx][:keys].join(".")
    end
    rule
  end
  
end # Rules
