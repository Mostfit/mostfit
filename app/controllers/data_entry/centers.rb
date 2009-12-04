module DataEntry
  class Centers < DataEntry::Controller
    def new
      @center = Center.new
      redirect(resource(:centers, :new, {:return => :data_entry}))
    end

    def edit
      if params[:query] and @center = Center.get(params[:query]) || Center.first(:name => params[:query]) || Center.first(:code => params[:query]) 
        @branch = @center.branch
        redirect(resource(@branch, @center, :edit, {:return => "/data_entry"}))
      elsif params[:query]
        message[:error]  = "No center by that id or name"
        display([], "centers/search")
      else
        display([], "centers/search")
      end
    end
  end
end
