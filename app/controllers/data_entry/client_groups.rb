module DataEntry
  class ClientGroups < DataEntry::Controller
    # provides :xml, :yaml, :js 
    def new
      only_provides :html
      @client_group = ClientGroup.new      
      @client_group.center_id = params[:center_id] if params[:center_id]
      request.xhr? ? render(:layout => false) : display(@client_group)
    end

    def edit(id)
      only_provides :html
      @client_group = ClientGroup.get(id)
      raise NotFound unless @client_group
      display @client_group
    end

    def create(client_group)
      @client_group = ClientGroup.new(client_group)
      if @client_group.save
        redirect(url(:data_entry), :message => {:notice => "Group was successfully created"})
      else
        message[:error] = "Group failed to be created"
        render :new
      end
    end

    def update(id, client_group)
      @client_group = ClientGroup.get(id)
      raise NotFound unless @client_group
      if @client_group.update(client_group)
        redirect resource(@client_group)
      else
        display @client_group, :edit
      end
    end    
  end # ClientGroups
end
