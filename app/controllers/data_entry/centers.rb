module DataEntry
  class Centers < DataEntry::Controller
  
    def index
      render
    end
    
    def new
      @center = Center.new
      render
    end

    def create(center)
      @center = Center.new(center)
      if @center.save
        redirect url(:enter_centers, :action => 'new'), :message => {:notice => "Center #{@center.name} created succesfully"}
      else
        render(:new)
      end
    end

    def edit
      if params[:id] and center = Center.get(params[:id]) || Center.first(:name => params[:id]) 
        @center = center
      elsif params[:id]
        message[:error]  = "No center by that id or name"
      end
      render
    end

    def update(id, center)
      @center = Center.get(id)
      raise NotFound unless @center
      if @center.update_attributes(center)
        redirect url(:enter_centers, :action => 'edit'), :message => {:notice => "Center '#{@center.name}' has been edited"}
      else
        render :edit  # error messages will be shown
      end
    end

  end
end # DataEntry
