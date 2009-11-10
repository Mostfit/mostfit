module DataEntry

class Clients < DataEntry::Controller
  provides :html, :xml
  def new
    @client = Client.new
    render
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
      params[:format]=='xml' ? display(@client): render(:new)
    end
  end

  def edit
    if params[:id] and client = Client.get(params[:id]) || Client.first(:name => params[:id]) || Client.first(:reference => params[:id])
      @client = client
    elsif params[:id]
      message[:error] = "No client by that id or name or reference number"
    elsif params[:client] and params[:client][:center_id]
      @center  = Center.get(params[:client][:center_id])
    end
    render
  end

  def update(id, client)
    @client = Client.get(id)
    raise NotFound unless @client
    if @client.update_attributes(client)
       redirect url(:enter_clients, :action => 'edit'), :message => {:notice => "Client '#{@client.name}' has been edited"}
    else
      render :edit  # error messages will be shown
    end
  end
end

end
