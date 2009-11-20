module DataEntry
  class ClientGroups < DataEntry::Controller
    # provides :xml, :yaml, :js 
    def new
      only_provides :html
      @client_group = ClientGroup.new      
      @client_group.center_id = params[:center_id] if params[:center_id]
      request.xhr? ? display([@client_group], "client_groups/new", :layout => false) : display([@client_group], "client_groups/new")
    end

    def index
      only_provides :html
      @client_groups = ClientGroup.all(:order => [:center_id])
      display [@client_groups], "client_groups/index"
    end

    def edit(id)
      only_provides :html      
      @client_group = ClientGroup.get(id)
      raise NotFound unless @client_group
      display @client_group, "client_groups/edit"
    end

    def create(client_group)
      only_provides :html, :json
      @client_group = ClientGroup.new(client_group)
      if @client_group.save
        request.xhr? ? display(@client_group) : redirect(url(:data_entry), :message => {:notice => "Group was successfully created"})
      else
        message[:error] = "Group failed to be created"
        request.xhr? ? display(@client_group.errors, :status => 406) : render(:new)
      end
    end

    def update(id, client_group)
      @client_group = ClientGroup.get(id)
      raise NotFound unless @client_group
      if @client_group.update(client_group)
        request.xhr? ? display(@client_group) : redirect(url(:data_entry), :message => {:notice => "Group was successfully saved"})
      else
        message[:error] = "Group failed to be saved"
        request.xhr? ? display(@client_group.errors, :status => 406) : render(:new)
      end
    end    
  end # ClientGroups    
end
