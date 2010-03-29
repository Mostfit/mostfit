class Search < Application
  def index
    if params[:query] and params[:query].length>0
      @branches = Branch.search(params[:query])
      @clients  = Client.search(params[:query])
      @centers  = Center.search(params[:query])
      @loans    = Loan.search(params[:query])
      @groups   = ClientGroup.search(params[:query])
      display [@branches, @clients, @centers, @loans]
    else
      display "No results"
    end
  end

  def advanced
    if params[:model] and [:branch, :center, :client, :loan, :client_group].include?(params[:model].to_sym)
      model = Kernel.const_get(params[:model].capitalize)
      hash  = params.deep_clone
      hash.delete(:controller)
      hash.delete(:action)
      hash.delete(:model)      
      instance_variable_set("@#{model.to_s.downcase.pluralize}", model.all(hash))
      render :index
    else
      render :advanced
    end
  end

  def reporting
    @forms = 1
    render :advanced
  end

  def get
    return "foo" if not params[:model] or params[:model].blank?
    model = Kernel.const_get(params[:model].singularize.camelcase)
    if not params[:property] or params[:property].blank?
      str = model.properties.collect{|x| 
        if relation = model.relationships.find{|rel| rel[1].child_key.map{|ck| ck.name}.include?(x.name)}
          "<option value='#{relation[0]}'>#{relation[0]}</option>"
        else
          "<option value='#{x.name.to_s}'>#{x.name.to_s}</option>"
        end
      }.join
      return str, :layout => false
    end
    property = model.properties.find{|p| p.name==params[:property].to_sym} || model.relationships[params[:property]]
    if not params[:operator] or params[:operator].blank?
      ops = get_operators(property)
      ops = [["", "Select operator"]] + ops
      return "#{ops.collect{|x| "<option value='#{x.first.to_s}'>#{x.last.to_s}"}.join('</option>')}</option>", :layout => false
    else      
      return get_values(model, property)
    end
  end
  
  private
  def get_values(model, property)
    if property.type==Date
      return date_select(property.name.to_s, Date.today, :id => "value")
    elsif [DataMapper::Types::Serial, Integer, Float, String, DataMapper::Types::Text].include?(property.type)
      return text_field(:id => "value", :name => property.name)
    elsif property.class==DataMapper::Associations::ManyToOne::Relationship
      return select(:id => "value", :name => property.name, :collection => property.parent_model.all, 
                    :value_method => :id, :text_method => :name,:prompt => "Choose #{property.name}")
    elsif property.type.class==Class
      return select(:id => "value", :name => property.name, :collection => property.type.flag_map.to_a, :prompt => "Choose #{property.name}")
    end
  end

  def get_operators(property)
    if property.type==DataMapper::Associations::ManyToOne::Relationship
      return [["eql", "equal"], ["not", "not equal"]]
    elsif [DataMapper::Types::Serial, Integer, Float, DateTime, Date, Time].include?(property.class)
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
end
