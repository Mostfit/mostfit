module DataEntry
  class Clients < DataEntry::Controller
    provides :html, :xml
    def new
      @center  = Center.get(params[:center_id])
      @branch = @center.branch if @center
      @client = Client.new
      redirect(resource(:clients, :new, {:return => :data_entry}))
    end
    
    def edit
      if (params[:id] and @client = Client.get(params[:id])) or (params[:client_id] and @client = Client.get(params[:client_id]) || Client.first(:name => params[:client_id]) || Client.first(:reference => params[:client_id]))
        @center = @client.center
        @branch = @center.branch
        redirect(resource(@branch, @center, @client, :edit, {:return => "/data_entry"}))
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
  end  
end
