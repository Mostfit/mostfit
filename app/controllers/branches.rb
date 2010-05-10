class Branches < Application
  provides :xml, :yaml, :js
  include DateParser

  def index
    @branches = Branch.paginate(:page => params[:page], :per_page => 15)
    display @branches
  end

  def show(id)
    @branch = Branch.get(id)
    raise NotFound unless @branch
    @centers = @branch.centers_with_paginate({:page => params[:page]}, session.user)
    display [@branch, @centers], 'centers/index'
  end
  
  def today(id)
    @date = params[:date] == nil ? Date.today : params[:date]
    @branch = Branch.get(id)
    raise NotFound unless @branch
    @centers = @branch.centers
    display [@branch, @centers]
  end

  def new
    only_provides :html
    @branch = Branch.new
    display @branch
  end

  def create(branch)
    @branch = Branch.new(branch)
    if @branch.save
      redirect(params[:return]||resource(:branches), :message => {:notice => "Branch '#{@branch.name}' successfully created"})
    else
      message[:error] = "Branch failed to be created"
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
      redirect(params[:return]||resource(:branches), :message => {:notice => "Branch '#{@branch.name}' has been edited"})
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

  # this redirects to the proper url, used from the router
  def redirect_to_show(id)
    raise NotFound unless @branch = Branch.get(id)
    redirect resource(@branch)
  end
end # Branches
