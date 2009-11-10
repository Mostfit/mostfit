module DataEntry
  class Branches < DataEntry::Controller  
    def index
      render
    end
    
    def new
      @branch = Branch.new
      render
    end

    def create(branch)
      @branch = Branch.new(branch)
      if @branch.save
        redirect url(:enter_branches, :action => 'new'), :message => {:notice => "Branch #{@branch.name} created succesfully"}
      else
        render(:new)
      end
    end

    def edit
      if params[:id] and branch = (Branch.get(params[:id]) || Branch.first(:name => params[:id]))
        @branch = branch
      elsif params[:id]
        message[:error]  = "No branch by that id or name"
      end
      render
    end
    
    def update(id, branch)
      @branch = Branch.get(id)
      raise NotFound unless @branch
      if @branch.update_attributes(branch)
        redirect url(:enter_branches, :action => 'edit'), :message => {:notice => "Branch '#{@branch.name}' has been edited"}
      else
        render :edit  # error messages will be shown
      end
    end    
  end
end # DataEntry
