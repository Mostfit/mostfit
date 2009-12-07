module DataEntry
  class Branches < DataEntry::Controller  
    def new
      @branch = Branch.new
      redirect(resource(:branches, :new, {:return => :data_entry}))
    end

    def edit
      if params[:query] and @branch = (Branch.get(params[:query]) || Branch.first(:name => params[:query]) || Branch.first(:code => params[:query]))
        redirect(resource(@branch, :edit, {:return => "/data_entry"}))
      elsif params[:query]
        message[:error]  = "No branch by that id or name"
        display([], "branches/search")
      else
        display([], "branches/search")
      end
    end
  end
end # DataEntry
