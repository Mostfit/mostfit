class Search < Application
  def old
    model = Kernel.const_get(params[:model])
    parameter = params[:by].snake_case.to_sym
    @object = model.all( parameter => params[:value])[0]
    raise NotFound unless @object
    redirect "/#{model.to_s.snake_case.pluralize}/#{@object.id}"
  end

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
      display "No results"
    end
  end
end
