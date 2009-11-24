module DataEntry
  class Clients < DataEntry::Controller
    provides :html, :xml
    def new
      @client = Client.new
      display([@client], "clients/new")
    end
    
    def create(client)
      @client = Client.new(client)
      if @client.save
        if params[:format]=='xml'#for xml thing return xml response
          display @client, ""
        else
          redirect url(:enter_clients, :action => 'new'), :message => {:notice => "Client '#{@client.name}' was successfully created"}
        end
      else
        params[:format]=='xml' ? display(@client): display([@clients], "clients/new")
      end
    end
        
    def edit
      if (params[:id] and @client = Client.get(params[:id])) or (params[:client_id] and @client = Client.get(params[:client_id]) || Client.first(:name => params[:client_id]) || Client.first(:reference => params[:client_id]))
        @center = @client.center
        @branch = @center.branch
        display([@client, @center, @branch], "clients/edit")
      elsif params[:client_id]
        message[:error] = "No client by that id or name or reference number"
        display([@center], "clients/search")
      elsif params[:client] and params[:client][:center_id]
        @center  = Center.get(params[:client][:center_id])
        display([@center], "clients/search")
      else
        display([], "clients/search")
      end
    end
    
    def update(id, client)
      @client = Client.get(id)
      raise NotFound unless @client    
      if @client.update_attributes(client)
        redirect url(:enter_clients, :action => 'index'), :message => {:notice => "Client '#{@client.name}' has been edited"}
      else
        @center = @client.center
        @branch = @center.branch
        display([@client, @center, @branch], "clients/edit")
      end
    end
  end  
end
