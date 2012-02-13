class Clients < Application
  before :get_context, :exclude => ['redirect_to_show', 'bulk_entry']
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
    if Client.descendants.count == 1
      only_provides :html
      @client = Client.new
      display @client
    else
      if params[:client_type]
        @client = Kernel.const_get(params[:client_type].camel_case).new
        display @client
      else
        render
      end
    end
  end

  def create(client)
    model_name = (params[:client_type])
    model = Kernel.const_get(model_name)
    client = params[:client].merge(params[model_name.snake_case])
    @client = model.new(client)
    @client.center = @center if @center# set direct context
    @client.created_by_user_id = session.user.id
    if @client.save
      if params[:format] and API_SUPPORT_FORMAT.include?(params[:format])
        display @client
      else
        redirect(params[:return]||resource(@branch, @center, :clients), :message => {:notice => "Client '#{@client.name}' (Id:#{@client.id}) successfully created"})
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
    display @client, :template => "clients/edit"
  end

  def update(id, client)
    @client = Client.get(id)
    raise NotFound unless @client
    disallow_updation_of_verified_clients
    client = params[:client].merge(params[@client.class.to_s.snake_case])
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
          redirect(params[:return]||resource(@branch, @center, @client), :message => {:notice => "Client '#{@client.name}' (Id:#{@client.id}) has been edited"})
        else
          redirect(resource(@client, :edit), :message => {:notice => "Client '#{@client.name}' (Id:#{@client.id}) has been edited"})
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

  def move_to_center(id)
    debugger
    @client = Client.get(id)
    raise NotFound unless @client
    @center = @client.center
    @date = Date.parse(params[:date]) rescue nil
    @new_center = Center.get(params[:new_center_id])
    if @date and @new_center
      if @client.move_to_center(@new_center, @date)
        redirect resource(@client), :message => {:success => "Client has been moved from <b>#{@center.name}</b> to <b>#{@new_center.name}</b>"}
      else
        redirect resource(@client), :message => {:error => "Client <b>could not</b> moved from <b>#{@center.name}</b> to <b>#{@new_center.name}</b>"}
      end
    else
      redirect resource(@client), :message => {:error => "Date not valid or new center does not exist"}
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
      redirect resource(@branch, @center, :clients), :message => {:notice => "Client '#{@client.name}' (Id:#{@client.id}) has been deleted"}
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
  
  def bulk_move
    if request.method == :get
      @errors = {}
      @center = Center.get(params[:center_id])
      raise NotFound unless @center
      @clients = @center.clients
      render
    else
      debugger
      @center = Center.get(params[:center_id])
      raise NotFound unless @center
      @date = Date.parse(params[:date]) rescue nil
      @new_center = Center.get(params[:new_center_id])
      if @date and @new_center
        Client.transaction do |t|
          @center.clients.each do |c|
            debugger
            c.move_to_center(@new_center, @date)
          end
        end
      end
      redirect resource(@new_center)
    end
  end

  def bulk_entry
    if request.method == :get
      @errors = {}
      render
    else
      @center = Center.get(params[:center_id])
      @errors = {}
      @errors[:center] = "Please choose a center" unless @center
      if @errors.blank?
        @clients = params[:clients].each do |k,v| 
          if v.values.join.length > 0 # if it isn't one of the blank rows
            # create the client
            c = Client.new(v.merge({:center_id => params[:center_id], 
                                     :created_by_staff_member_id => @center.manager, 
                                     :created_by_user_id => session.user.id}))
            if c.save
              params[:clients].delete(k) 
            else
              @errors[k] = c.errors # keep a copy of the errors in a global variable
            end
          else
            params[:clients].delete(k) # this worked. delete this params so you can report errors on all the params that remain
          end
        end
      end
      if params[:clients].keys.length > 0 # there are some errors
        render # errors will be shown
      else
        return_to = session.user.role == :data_entry ? url(:data_entry) : resource(@center)
        redirect return_to, :message => {:notice => "all clients succesfully added"}
      end
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

# This is how you massage params to fit the needs of various client types, by adding a before hook as below

# class JlgClients < Clients

#   before :do_params, :only => [:create, :update]

#   def do_params
#     params[:jlg_client][:member_details] = Marshal.dump(params[:jlg_client][:member_details])
#     params[:jlg_client][:expenses] = Marshal.dump(params[:jlg_client][:expenses])
#   end

# end
