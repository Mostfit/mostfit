module DataEntry
  class Branches < DataEntry::Controller  
    def new
      @branch = Branch.new
      display([@branch], "branches/new")
    end

    def create(branch)
      @branch = Branch.new(branch)
      if @branch.save
        redirect url(:data_entry), :message => {:notice => "Branch #{@branch.name} created succesfully. ID: #{@branch.id}"}
      else
        display([@branch], "branches/new")
      end
    end

    def edit
      if params[:query] and @branch = (Branch.get(params[:query]) || Branch.first(:name => params[:query]) || Branch.first(:code => params[:query]))
        display([@branch], "branches/edit")
      elsif params[:query]
        message[:error]  = "No branch by that id or name"
        display([], "branches/search")
      else
        display([], "branches/search")
      end
    end
    
    def update(id, branch)
      @branch = Branch.get(id)
      raise NotFound unless @branch
      if @branch.update_attributes(branch)
        redirect url(:enter_branches, :action => 'edit'), :message => {:notice => "Branch '#{@branch.name}' has been edited"}
      else
        display([@branch], "branches/edit")  # error messages will be shown
      end
    end    
  end
end # DataEntry
