class ClientTypes < Application
  # provides :xml, :yaml, :js

  def index
    @client_types = ClientType.all
    display @client_types
  end

  def show(id)
    @client_type = ClientType.get(id)
    raise NotFound unless @client_type
    display @client_type
  end

  def new
    only_provides :html
    @client_type = ClientType.new
    display @client_type
  end

  def edit(id)
    only_provides :html
    @client_type = ClientType.get(id)
    raise NotFound unless @client_type
    display @client_type
  end

  def create(client_type)
    @client_type = ClientType.new(client_type)
    @client_type.fees = Fee.all(:id => params[:fees].keys) if params[:fees]
    if @client_type.save
      redirect resource(@client_type), :message => {:notice => "ClientType was successfully created"}
    else
      message[:error] = "ClientType failed to be created"
      render :new
    end
  end

  def update(id, client_type)
    @client_type = ClientType.get(id)
    raise NotFound unless @client_type
    if @client_type.update(client_type)
       redirect resource(@client_type)
    else
      display @client_type, :edit
    end
  end

  def destroy(id)
    @client_type = ClientType.get(id)
    raise NotFound unless @client_type
    if @client_type.destroy
      redirect resource(:client_types)
    else
      raise InternalServerError
    end
  end

end # ClientTypes
