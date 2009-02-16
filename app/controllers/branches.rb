class Branches < Application
  provides :xml, :yaml, :js
  before :ensure_has_mis_manager_privileges, :only => ['new','create','edit','update','destroy','delete']

  def index
    @branches = Branch.all
    display @branches
  end

  def show(id)
    @branch = Branch.get(id)
    raise NotFound unless @branch
    @centers = @branch.centers
    display [@branch, @centers], 'centers/index'
  end

  def new
    only_provides :html
    @branch = Branch.new
    display @branch
  end

  def create(branch)
    @branch = Branch.new(branch)
    if @branch.save
      redirect resource(:branches), :message => {:notice => "Branch '#{@branch.name}' successfully created"}
    else
#       message[:error] = "Branch failed to be created"
      render :new  # error messages will show
    end
  end

  def edit(id)
    only_provides :html
    @branch = Branch.get(id)
    raise NotFound unless @branch
    display @branch
  end

  def update(id, branch)
    @branch = Branch.get(id)
    raise NotFound unless @branch
    if @branch.update_attributes(branch)
      redirect resource(:branches), :message => {:notice => "Branch '#{@branch.name}' has been edited"}
    else
      display @branch, :edit  # error messages will show
    end
  end

  def delete(id)
    edit(id)  # so far identical to edit
  end

  def destroy(id)
    @branch = Branch.get(id)
    raise NotFound unless @branch
    if @branch.destroy
      redirect resource(:branches), :message => {:notice => "Branch '#{@branch.name}' has been deleted"}
    else
      raise InternalServerError
    end
  end

end # Branches
