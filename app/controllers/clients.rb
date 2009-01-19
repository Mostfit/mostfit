class Clients < Application
  before :get_parent
  # provides :xml, :yaml, :js

  def index
    @clients = Client.all
    display @clients
  end

  def show(id)
    @client = Client.get(id)
    raise NotFound unless @client
    display @client
  end

  def new
    only_provides :html
    @client = Client.new
    display @client
  end

  def create(client)
    @client = Client.new(client)
    if @client.save
      redirect resource(@branch, @center, :clients), :message => {:notice => "Client '#{@client.name}' was successfully created"}
    else
#       message[:error] = "Client failed to be created"
      render :new  # error messages will be shown
    end
  end

  def edit(id)
    only_provides :html
    @client = Client.get(id)
    raise NotFound unless @client
    display @client
  end

  def update(id, client)
    @client = Client.get(id)
    raise NotFound unless @client
    if @client.update_attributes(client)
       redirect resource(@branch, @center, :clients), :message => {:notice => "Client '#{@client.name}' has been edited"}
    else
      display @client, :edit  # error messages will be shown
    end
  end

  def delete(id)
    edit(id)  # so far these are the same
  end

  def destroy(id)
    @client = Client.get(id)
    raise NotFound unless @client
    if @client.destroy
      redirect resource(@branch, @center, :clients), :message => {:notice => "Client '#{@client.name}' has been deleted"}
    else
      raise InternalServerError
    end
  end

  private
  def get_parent
    @branch = Branch.get(params[:branch_id])
    @center = Center.get(params[:center_id])
  end
end # Clients
