class Search < Application

  def index
    debugger
    model = Kernel.const_get(params[:model])
    parameter = params[:by].snake_case.to_sym
    @object = model.all( parameter => params[:value])[0]
    raise NotFound unless @object
    redirect "/#{model.to_s.snake_case.pluralize}/#{@object.id}"
  end
  
end
