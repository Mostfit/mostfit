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
      @branch = (params[:branch] and params[:branch][:id]) ? Branch.get(params[:branch][:id]) : Branch.new
      render
    end

    def update(id, branch)
      @branch = Branch.get(id)
      raise NotFound unless @branch
      if @branch.update_attributes(branch)
        redirect url(:enter_branches, :action => 'edit'), :message => {:notice => "branch '#{@branch.name}' has been edited"}
      else
        render :edit  # error messages will be shown
      end
    end

  end
end # DataEntry
