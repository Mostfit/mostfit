class Clients < Application
  before :get_context, :exclude => ['redirect_to_show']
  provides :xml, :yaml, :js

  def index
#    @clients = @center.clients
#    display @clients
    if request.xhr?
      @clients = @center.clients
      @loans   = @clients.loans
      partial "clients/list"
    else
      redirect resource(@branch, @center)  # redirecting to the centers show where the @date shizzle works
    end
  end

  def show(id)
    @option = params[:option] if params[:option]    
    @client = Client.get(id)
    raise NotFound unless @client
    
    if @center
      @loans = @loans ? @loans.find_all{|l| l.client_id == @client.id} : @client.loans
      display [@client, @loans, @option], 'loans/index'
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
      if params[:format] and API_SUPPORT_FORMAT.include?(params[:format])
        display @client
      else
        redirect(params[:return]||resource(@branch, @center, :clients), :message => {:notice => "Client '#{@client.name}' successfully created"})
      end
    else
      if params[:format] and API_SUPPORT_FORMAT.include?(params[:format])
        display @client
      else
        render :new  # error messages will be shown
      end
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
    @client.update_attributes(client)      
    if @client.errors.blank?
      if params[:tags]
        @client.tags = params[:tags].keys.map{|k| k.to_sym} 
      else
        @client.tags = []
      end
      @client.save
      if params[:format] and API_SUPPORT_FORMAT.include?(params[:format])
        if params[:client] and params[:client][:fingerprint]
          doc = Base64.decode64(params[:client][:fingerprint]) 
          temp = File.new("tmp/client_#{@client.id}_fingerprint.fpt", "w")
          File.open( temp.path, 'wb') do |f|
            f.write(doc)
          end
          doc_file = File.open(temp.path, 'rb')
          @client.fingerprint = doc_file
          @client.save
          File.delete("tmp/client_#{@client.id}_fingerprint.fpt")
        end
        display @client
      else
        if @branch and @center
          redirect(params[:return]||resource(@branch, @center, @client), :message => {:notice => "Client '#{@client.name}' has been edited"})
        else
          redirect(resource(@client, :edit), :message => {:notice => "Client '#{@client.name}' has been edited"})
        end
      end
    else
      if params[:format] and API_SUPPORT_FORMAT.include?(params[:format])
        display @client
      else
        display @client, :edit  # error messages will be shown
      end
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

  def levy_fees(id)
    @client = Client.get(id)
    raise NotFound unless @client
    @client.levy_fees(false)
    redirect resource(@client) + "#misc", :message => {:notice => 'Fees levied'}
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
  
  def inactive_client_count
    @data = Client.all(:active => false, :inactive_reason => 'death_of_client') + Client.all(:active => false, :inactive_reason => 'death_of_spouse')
    render
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
