class Clients < Application
  before :get_context, :exclude => ['redirect_to_show']
  provides :xml, :yaml, :js

  def index
#    @clients = @center.clients
#    display @clients
    redirect resource(@branch, @center)  # redirecting to the centers show where the @date shizzle works
  end

  def show(id)
    @client = Client.get(id)
    raise NotFound unless @client
    
    if @center
      @loans = @client.loans
      display [@client, @loans], 'loans/index'
    else
      redirect_to_show(params[:id])
    end
  end

  def new
    only_provides :html
    @client = Client.new
    display @client
  end

  def create(client)
    @client = Client.new(client)
    @client.center = @center if @center# set direct context
    @client.created_by_user_id = session.user.id
    if @client.save
      redirect(params[:return]||resource(@branch, @center, :clients), :message => {:notice => "Client '#{@client.name}' successfully created"})
    else
      render :new  # error messages will be shown
    end
  end

  def edit(id)
    only_provides :html
    @client = Client.get(id)
    raise NotFound unless @client
    disallow_updation_of_verified_clients
    display @client
  end

  def update(id, client)
    @client = Client.get(id)
    raise NotFound unless @client
    disallow_updation_of_verified_clients
    if @client.update_attributes(client)      
      if params[:tags]
        @client.tags = params[:tags].keys.map{|k| k.to_sym} 
      else
        @client.tags = []
      end
      @client.save
      if @branch and @center
        redirect(params[:return]||resource(@branch, @center, @client), :message => {:notice => "Client '#{@client.name}' has been edited"})
      else
        redirect(resource(@client, :edit), :message => {:notice => "Client '#{@client.name}' has been edited"})
      end
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
    disallow_updation_of_verified_clients
    if @client.destroy
      redirect resource(@branch, @center, :clients), :message => {:notice => "Client '#{@client.name}' has been deleted"}
    else
      raise InternalServerError
    end
  end
  
  def make_center_leader(id)
    @client = Client.get(id)
    raise NotFound unless @client
    if @client.make_center_leader
      return "Made center leader"
    else
      return "Cannot be made center leader"
    end
  end
  
  # this redirects to the proper url, used from the router
  def redirect_to_show(id)
    raise NotFound unless @client = Client.get(id)
    if @client.center
      redirect resource(@client.center.branch, @client.center, @client)
    else
      redirect resource(@client, :edit)
    end
  end

  private
  def get_context
    if params[:branch_id] and params[:center_id] 
      @branch = Branch.get(params[:branch_id]) 
      @center = Center.get(params[:center_id]) 
      raise NotFound unless @branch and @center
    end
  end
  def disallow_updation_of_verified_clients
    raise NotPrivileged if @client.verified_by_user_id and not session.user.admin?
  end
end # Clients
