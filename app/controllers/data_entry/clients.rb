module DataEntry

class Clients < DataEntry::Controller
  def new
    @client = Client.new
    render
  end

  def create(client)
    @client = Client.new(client)
    if @client.save
      redirect url(:enter_clients, :action => 'new'), :message => {:notice => "Client '#{@client.name}' was successfully created"}
    else
      render :new  # error messages will be shown
    end
  end

  def edit
    @client = Client.new
    params[:client][:center_id]
    @center = Center.get(params[:client][:center_id])
    @center = nil if not @center
    render
  end

  def update
  end

  def delete
  end

  def destroy
  end
end

end