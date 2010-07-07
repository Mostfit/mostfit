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
    debugger
    @rule = Rule.new(rule)
    if @rule.save
      redirect resource(@rule), :message => {:notice => "Rule was successfully created"}
    else
      message[:error] = "Rule failed to be created"
      render :new
    end
  end

  def update(id, rule)
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
    if Mostfit::Business::Rules.all_models.index(model.to_sym)
      model = Kernel.const_get(model.camelcase)
      choices = (model.properties.map{|x| x.name.to_s} + model.relationships.keys)
      field   = :select
    elsif Mostfit::Business::Rules.all_models.index(model.singularize.to_sym)
      # it is an array. Choices are count, max, min etc
      choices = ['count', 'value']
      model = Kernel.const_get(model.singularize.camelcase)      
      choices += model.relationships.keys
      field   = :select
    elsif ['count', 'max', 'min', 'value'].include?(model)      
      field = :select
      choices = ['<=', '>=', '=']
    elsif ['<=', '>=', '='].include?(model)
      field = :text_field
    end

    select_id = "select_#{params[:select_id].to_i+1}" if params[:select_id]

    if field==:select
      render(select(:name => "rule[condition][]", :collection => choices, :class => "rules", :prompt => "select property", :id => select_id), :layout => false)
    else
      render(text_field(:name => "rule[condition][]", :class => "rules"), :layout => false, :id => select_id)
    end
  end
  
end # Rules
