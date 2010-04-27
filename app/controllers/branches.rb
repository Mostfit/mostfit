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
    @centers = @branch.centers_with_paginate(:page => params[:page])
    display [@branch, @centers], 'centers/index'
  end

  def moreinfo(id)
    @render_form = true
    @render_form = false if params[:_target_]
    @from_date = params[:from_date] ? parse_date(params[:from_date]) : Date.min_date
    @to_date   = params[:to_date]   ? parse_date(params[:to_date])   : Date.today
    allow_nil  = (params[:from_date] or params[:to_date]) ? false : true
    @branch = Branch.get(id)
    raise NotFound unless @branch

    if allow_nil
      @centers       = @branch.centers
      @clients       = @centers.clients(:fields => [:id])
    else
      @centers       = @branch.centers(:creation_date.lte => @to_date, :creation_date.gte => @from_date)
      @clients       = @centers.clients(:fields => [:id], :date_joined.lte => @to_date, :date_joined.gte => @from_date)
    end

    @centers_count = @centers.count
    @groups_count  = (@centers_count>0) ? @centers.client_groups(:fields => [:id]).count : 0
    @clients_count = (@centers_count>0) ? @clients.count : 0
    @payments      = Payment.collected_for(@branch, @from_date, @to_date)
    @fees          = Fee.collected_for(@branch, @from_date, @to_date)
    @loan_disbursed= LoanHistory.amount_disbursed_for(@branch, @from_date, @to_date)
    @loan_data     = LoanHistory.sum_outstanding_for(@branch, @from_date, @to_date)
    @defaulted     = LoanHistory.defaulted_loan_info_for(@branch, @to_date)
    render :file => 'branches/moreinfo', :layout => false
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
