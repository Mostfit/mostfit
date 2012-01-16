class Searches < Application
  
  def index
    if params[:query] and params[:query].length>=1
      per_page       = request.xhr? ? 11 : 100
      @branches      = Branch.search(params[:query], per_page)
      @clients       = Client.search(params[:query], per_page)
      @centers       = Center.search(params[:query], per_page)
      @loans         = Loan.search(params[:query], per_page)
      @client_groups = ClientGroup.search(params[:query], per_page)
      @staff_members = StaffMember.search(params[:query], per_page)
      @bookmarks     = Bookmark.search(params[:query], session.user, per_page)
    end
    @floating = true if request.xhr?
    render :layout => layout?
  end

  def list
    # returns a list based on params
    # useful for stuff like autocomplete
    only_provides :json
    model = Kernel.const_get(params[:model].camelcase)
    if params[:q]
      # this code block handles multiple search criteria such as
      # q[name.like]=tam%25&q[amount]=25000
      q = params[:q].map do |k,v| 
        if k.match(".")
          n,o = k.split(".")
          k = DataMapper::Query::Operator.new(n, o.to_sym)
          [k, v]
        else
          [k.to_sym, v.to_sym]
        end
      end.to_hash || {}
    else
      # here we handle stuff from jquery autocomplete ui which send in args thus
      # op=name.like&term=xyz
      n,o = params[:op].split(".")
      term = "%#{params[:term]}%" if o == "like"
      q = {DataMapper::Query::Operator.new(n, o.to_sym) =>  term}
    end
    q = q.merge({:order => [:name]})
    q = q.merge(:limit => 25, :offset => (params[:page].to_i - 1) * 25) if params[:page]
    fn = params[:as] ? "to_#{params[:as]}" : "all"
    @list = model.send(fn,q).to_json
  end

  def advanced
    if params[:model] and [:branch, :center, :client, :loan, :client_group].include?(params[:model].to_sym)
      model = Kernel.const_get(params[:model].capitalize)
      hash  = params.deep_clone
      hash.delete(:controller)
      hash.delete(:action)
      hash.delete(:model)      
      instance_variable_set("@#{model.to_s.downcase.pluralize}", model.all(hash))
      @floating = false
      render :index
    else
      render :advanced
    end
  end

  #get fields for all the models selected in form
  def fields
    @properties = get_all_properties(params)
    partial :fields
  end

  def edit
    @hash  = YAML::load(params[:parameters])
    @properties = get_all_properties(@hash)
    render
  end  

  def reporting
    @counter = params[:counter]||1
    if request.xhr?
      @model = Kernel.const_get(params[:model].camelcase)
      if params[:more]=="chain"
        @model = @model.relationships.find_all{|key, prop| prop.class==DataMapper::Associations::OneToMany::Relationship}.map{|x| x[0].singularize}
      elsif params[:model]
        @properties = get_properties_for(@model)
      end
      partial :form
    elsif request.method==:get and (not params[:_method] == "post")
      render :advanced, :layout => layout?
    elsif request.method==:post or params[:_method] == "post"
      @search  = Search.new(params)
      @bookmark= Bookmark.new
      if params[:_method] == "post" # don't run the query while defining the report, only when requested from a link
        @objects = @search.process
        @fields  = params[:fields].map{|k,v| [k,v.keys]}.to_hash

        # we need to find the fields that are required.
        # reproduced below is Piyush Ranjan's code from the :reporting haml file
        # certainly looks as though it might be optimised better
        if params[:precedence]
          @precedence = params[:precedence]
        else
          @precedence = Marshal.load(Marshal.dump(@fields))   # this is for situations where
          counter = 1                                         # a precedence is not specified
          @precedence.each{|model, properties|                # not optimising this code now
            properties.each{|k, v|                            # but could do with some at some point
              properties[k] = counter                         # TODO optimize this code
              counter+=1
            }
          }
        end
        
        @field_order = @fields.map{|k,vs| vs.map{|v| [@precedence[k][v],[k,v]]}}.flatten(1).to_hash
        
        # @field_order now looks like 
        # {"6"=>["center", "meeting_day"], "1"=>["center", "name"], "2"=>["branch", "name"], "3"=>["client", "reference"], "4"=>["client", "name"], "5"=>["branch", "address"]}
        # oh, what I wouldn't give for sortable hashes!
        # @field_order is only for presentation purposes. So, for now, on with gathering our results
        #
        # shameless plug - do check out an earlier version of this file
        
        # we have enough information now to preload all the objects into a nice hash.
        # the previous version git commit b6db423f85e and prior would make too many SQL calls
        # and so would be very slow for large datasets with a lot of relationships.
        # we try and avoid it by loading everything we need upfront into a hash
        
        # params[:model] states which is the order that the models are chained in. this is cool for several reasons,
        # chief being that we are guaranteed that any model will always have other_model_id field for the preceding model in the chain.
        # it makes it easy for us to build a hash like
        # {:client => {:id => [:fields..., :center_id]...}, :center => {:id => [:fields....:branch_id]...}, :branch => {:id => [:fields]}
        # assuming we have params[:model] = {"1" => "branch", "2" => "center", "3"=> "client"}
        # we will have @objects = collection of clients.
        # we now need to end up with result = {:clients =>  @objects, :center => @object.centers, :branches => @objects.centers.branches}
        
        # the following code bulk loads all the relevant OBJECTS into a nice hash and saves you having to make shitloads of SQL calls
        relevant_models = params["model"].sort_by{|serial,property| 0 - serial.to_i}.map{|a| a[1]} # sorted list of chained models
        @result = {}; last_r = nil
        relevant_models.each_with_index do |model,i| 
          next_r = relevant_models[i + 1]
          relevant_fields = (@fields[model] + ["id",("#{next_r}_id" if next_r)]).uniq.compact.map(&:to_sym)  # i.e. center_id is a relevant field for client, along with the explicitly stated fields
          @result[model] = Kernel.const_get(model.camel_case).all(:id => @objects[model.to_sym], :fields => relevant_fields).aggregate(*relevant_fields).map{|rs| relevant_fields.zip([rs].flatten).to_hash}.map{|a| [a[:id],a]}.to_hash # some mangling to get a proper hash
        end
        
        # this small couplet below turns the @result hash into a series of rows, just waiting to be printed
        @rows = @objects[relevant_models.first.to_sym].map do |oid|
          last_model = nil
          relevant_models.map do |m|
            k = (last_model or Nothing)["#{m}_id".to_sym] || oid
            r = @result[m][k]
            last_model = r
            [m,r]
          end.to_hash
        end
      else
      end
      render :reporting
    end
  end

  def get
    return "" if not params[:model] or params[:model].blank?
    #params[:counter] = (params[:counter] ? params[:counter].to_i : 0)
    model = Kernel.const_get(params[:model][params[:counter]].singularize.camelcase)

    if not params[:property] or not params[:property][params[:counter]] or params[:property][params[:counter]].blank?
      return "<option value=''>select property</option>"+get_properties_for(model).collect{|prop| "<option value='#{prop}'>#{prop}</option>"}.join, :layout => false
    end

    property = model.properties.find{|p| p.name.to_s==params[:property][params[:counter]]} || model.relationships[params[:property][params[:counter]]]

    if not params[:operator] or not params[:operator][params[:counter]] or params[:operator][params[:counter]].blank?
      ops = Search.get_operators(property)
      ops = [["", "Select operator"]] + ops
      return "#{ops.collect{|x| "<option value='#{x.first.to_s}'>#{x.last.to_s}"}.join('</option>')}</option>", :layout => false
    else
      return get_values(model, property, params[:counter])
    end

  end
  
  private
  def get_values(model, property, counter, value = nil)
    operator = params[:operator].is_a?(Hash) ? params[:operator][params[:counter]] : params[:operator]
    value = value.to_s if value
    if property.type==Date or property.type==DateTime
      return date_select("value[#{counter}][#{property.name}]", value||Date.today, :id => "value_#{counter}")
    elsif [DataMapper::Types::Serial, Integer, Float, String, DataMapper::Types::Text].include?(property.type)
      if operator == "in"
        return "<select multiple='multiple' class='chosen' id='value_#{counter}' name='value[#{counter}][name][]'>" + model.all.aggregate(property).map{|p| "<option value='#{p}'>#{p}</option>"}.join + "</select>"
      else
        return text_field(:id => "value_#{counter}", :name => "value[#{counter}][#{property.name}]", :value => value)
      end
    elsif property.class==DataMapper::Associations::ManyToOne::Relationship
      return select(:id => "value_#{counter}", :name => "value[#{counter}][#{property.name}]", :collection => property.parent_model.all, 
                    :value_method => :id, :text_method => :name,:prompt => "Choose #{property.name}", :selected => value)
    elsif property.type==DataMapper::Types::Boolean
      return select(:id => "value_#{counter}", :name => "value[#{counter}][#{property.name}]", 
                    :collection => [["true", "yes"], ["false", "no"]], :prompt => "Choose #{property.name}", :selected => value)
    elsif property.type == DataMapper::Types::Discriminator
      return select(:id => "value_#{counter}", :name => "value[#{counter}][#{property.name}]",
                    :collection => property.model.descendants.to_a.map{|e| [e.to_s, e.to_s]}, :prompt => "Choose #{property.name}", :selected => value)      
    elsif property.type.class==Class
      return select(:id => "value_#{counter}", :name => "value[#{counter}][#{property.name}]", 
                    :collection => property.type.flag_map.to_a, :prompt => "Choose #{property.name}", :selected => value)
    end
  end

  def get_properties_for(model)
    model.properties.collect{|x| 
      if relation = model.relationships.find{|rel| rel[1].child_key.map{|ck| ck.name}.include?(x.name)}
        relation[0]
      else
        x.name
      end
    }
  end

  def get_all_properties(params)
    hash  = params.deep_clone
    hash.delete(:controller)
    hash.delete(:action)
    properties = {}
    hash[:model].each{|counter, model|
      klass = Kernel.const_get(model.camelcase)
      properties[model] = get_properties_for(klass)
    }
    properties
  end
end
