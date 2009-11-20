module DataEntry
  class Centers < DataEntry::Controller
    def new
      @center = Center.new
      display([@center], "centers/new")
    end

    def create(center)
      @center = Center.new(center)
      if @center.save
        redirect(url(:data_entry), :message => {:notice => "Center #{@center.name} created succesfully. ID: #{@center.id}"})
      else
        display([@center], "centers/new")
      end
    end

    def edit
      if params[:query] and @center = Center.get(params[:query]) || Center.first(:name => params[:query]) || Center.first(:code => params[:query]) 
        @branch = @center.branch
        display([@center, @branch], "centers/edit")
      elsif params[:query]
        message[:error]  = "No center by that id or name"
        display([], "centers/search")
      else
        display([], "centers/search")
      end
    end

    def update(id, center)
      @center = Center.get(id)
      raise NotFound unless @center
      @branch = @center.branch

      if @center.update_attributes(center)
        redirect url(:enter_centers, :action => 'edit'), :message => {:notice => "Center '#{@center.name}' has been edited"}
      else
        display([@center, @branch], "centers/edit")
      end
    end

  end
end # DataEntry
