class Info < Application
  # serves info tab for branch
  def moreinfo(id)
    date_hash  = set_info_form_params

    klass      = Kernel.const_get(params[:for].camelcase)
    @obj       = klass.get(id)
    raise NotFound unless @obj

    if @obj.class==Region
      @areas     = @obj.areas(date_hash)
    elsif @obj.class==Area
      @branches  = @obj.branches(date_hash)
    elsif @obj.class==Branch
      @centers   = @obj.centers(date_hash)
    elsif @obj.class==Center
      @centers   = Center.all(:id =>@obj.id)
    elsif @obj.class==StaffMember
      @areas     = @obj.areas
      @branches  = @obj.branches
      @centers   = @obj.centers
    end
    @branches  = @areas.branches(date_hash)   if @areas and not @branches
    @centers   = @branches.centers(date_hash) if @branches and not @centers
    client_hash= date_hash+ {:fields => [:id]}
    @clients   = @centers.clients(client_hash)

    set_more_info(@obj)
    render :file => 'info/moreinfo', :layout => false
  end

private
  def set_info_form_params
    @render_form = true
    @render_form = false if params[:_target_]
    @from_date = params[:from_date] ? parse_date(params[:from_date]) : Date.min_date
    @to_date   = params[:to_date]   ? parse_date(params[:to_date])   : Date.today
    if params[:from_date]
      return {:creation_date.lte => @to_date, :creation_date.gte => @from_date}
    else
      return {}
    end
  end

  def set_more_info(obj)
    @centers_count = @centers.count
    @groups_count  = (@centers_count>0) ? @centers.client_groups(:fields => [:id]).count : 0
    @clients_count = (@centers_count>0) ? @clients.count : 0
    @payments      = Payment.collected_for(obj, @from_date, @to_date)
    @fees          = Fee.collected_for(obj, @from_date, @to_date)
    @loan_disbursed= LoanHistory.amount_disbursed_for(obj, @from_date, @to_date)
    @loan_data     = LoanHistory.sum_outstanding_for(obj, @from_date, @to_date)
    @defaulted     = LoanHistory.defaulted_loan_info_for(obj, @to_date)
  end
end
  
