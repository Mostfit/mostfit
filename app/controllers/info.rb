class Info < Application
  include DateParser
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
    @clients   = @centers.clients(client_hash)

    set_more_info(@obj)
    render :file => 'info/moreinfo', :layout => false
  end

  def exceptions(id)
    klass      = Kernel.const_get(params[:for].camelcase)
    @obj       = klass.get(id)
    raise NotFound unless @obj
    @center_ids = @obj.centers(:fields => [:id]).map{|x| x.id}
    @client_ids = @obj.clients(:fields => [:id]).map{|x| x.id}

    @amount_noteq_applied=repository.adapter.query(%Q{
       SELECT count(*) FROM loans l, clients cl, centers c, branches b 
       WHERE  b.id=#{@obj.id} AND c.branch_id=b.id AND cl.center_id=c.id AND l.client_id=cl.id
       AND l.amount!=l.amount_applied_for AND l.deleted_at is NULL and l.disbursal_date is not NULL 
    })
    @amount_noteq_approved=repository.adapter.query(%Q{
       SELECT count(*) FROM loans l, clients cl, centers c, branches b 
       WHERE  b.id=#{@obj.id} AND c.branch_id=b.id AND cl.center_id=c.id AND l.client_id=cl.id
       AND l.amount!=l.amount_sanctioned AND l.deleted_at is NULL and l.disbursal_date is not NULL 
    })
    @delayed_disbursals = repository.adapter.query(%Q{
       SELECT count(*) FROM loans l, clients cl, centers c, branches b 
       WHERE  b.id=#{@obj.id} AND c.branch_id=b.id AND cl.center_id=c.id AND l.client_id=cl.id
       AND    l.scheduled_disbursal_date < NOW() AND l.deleted_at is NULL and l.disbursal_date is NULL 
    })
    @delayed_repayments = LoanHistory.defaulted_loan_info_for(@obj)
    @loans_created_by_admin = User.all(:role => :admin).audit_trails(:action => :create, :auditable_type => "Loan").count(:auditable_id)
    @loans_edited_by_admin  = User.all(:role => :admin).audit_trails(:action => :update, :auditable_type => "Loan").count(:auditable_id)
    @loans_deleted_by_admin = User.all(:role => :admin).audit_trails(:action => :destroy,:auditable_type => "Loan").count(:auditable_id)
    @clients_without_insurance = (@client_ids - InsurancePolicy.all(:fields => [:client_id]).map{|x| x.client_id}).length
    render :file => 'info/exceptions', :layout => false
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

  def client_hash
    if params[:from_date]
      return {:fields => [:id], :date_joined.lte => @to_date, :date_joined.gte => @from_date}
    else
      return {:fields => [:id]}
    end
  end
  def set_more_info(obj)
    @centers_count   = @centers.count
    @groups_count    = (@centers_count>0) ? @centers.client_groups(:fields => [:id]).count : 0
    @clients_count   = (@centers_count>0) ? @clients.count : 0
    @payments        = Payment.collected_for(obj, @from_date, @to_date)
    @fees            = Fee.collected_for(obj, @from_date, @to_date)
    @total_disbursed = LoanHistory.amount_disbursed_for(obj, Date.min_date, Date.today)
    @loan_disbursed  = LoanHistory.amount_disbursed_for(obj, @from_date, @to_date)
    @loan_data       = LoanHistory.sum_outstanding_for(obj, @from_date, @to_date)
    @defaulted       = LoanHistory.defaulted_loan_info_for(obj, @to_date)
  end
end
  
