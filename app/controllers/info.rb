class Info < Application
  include DateParser
  # serves info tab for branch
  def branchinfo(id)
    @branch                                                  = Branch.get(id)
    @loan_histories                                          = LoanHistory.all(:branch_id => id)
    
    @centers = @branch.centers
    @center_count                                            = @centers.aggregate(:all.count)
    @client_count                                            = @centers.clients.aggregate(:all.count)
    @loan_count                                              = @loan_histories.aggregate(:loan_id).count
    @borrower_client_count                                   = @loan_histories.aggregate(:client_id).count
    # all the various statuses
    cols = [:applied, :approved, :disbursed, :preclosed].map{|c| [c, "#{c}_count".to_sym]}.flatten
    agg_cols = cols.map{|c| DataMapper::Query::Operator.new(c, :sum)}
    @statuses = cols.zip(@loan_histories.aggregate(*agg_cols))
    @active_client_count                                          = LoanHistory.latest_by_status(:branch_id => id, :status => :outstanding).aggregate(:client_id.count)
    @principal_paid                                          = @loan_histories.aggregate(:principal_paid.sum)
    @interest_paid                                           = @loan_histories.aggregate(:interest_paid.sum)
    @fees_paid                                               = @loan_histories.aggregate(:fees_paid_today.sum)
    @total_paid                                              = @principal_paid + @interest_paid + @fees_paid
    render :layout => false
  end


  def moreinfo(id)
    new_date_hash, upto_date_hash  = set_info_form_params
    
    klass      = Kernel.const_get(params[:for].camelcase)
    @obj       = klass.get(id)
    raise NotFound unless @obj
    
    if @obj.class == Region
      @areas, @branches, @centers, @clients = {}, {}, {}, {}
      new_date_hash ||= {}
      upto_date_hash ||= {}
      branch_key = "branch.area.region_id"
      
      @areas[:new]  = @obj.areas(new_date_hash)
      @areas[:upto] = @obj.areas(upto_date_hash)
      
      @branches[:new]  = @obj.areas.branches(new_date_hash)
      @branches[:upto] = @obj.areas.branches(upto_date_hash)
      
      @centers[:new]  = Center.all(new_date_hash.merge({branch_key => @obj.id}))
      @centers[:upto] = Center.all(upto_date_hash.merge({branch_key => @obj.id}))
      
      @clients[:new]  = Client.all(client_hash(:new).merge({"center.#{branch_key}" => @obj.id, :fields => [:id]}))
      @clients[:upto] = Client.all(client_hash(:upto).merge({"center.#{branch_key}" => @obj.id, :fields => [:id]}))
      
      hash = {"center.#{branch_key}" => @obj.id}
      hash["center.creation_date.lte"] = new_date_hash[:creation_date.lte] if new_date_hash[:creation_date.lte]
      hash["center.creation_date.gte"] = new_date_hash[:creation_date.gte] if new_date_hash[:creation_date.gte]

      @groups_new_count   = ClientGroup.all(hash).count
      hash["center.creation_date.lte"] = upto_date_hash[:creation_date.gte] if upto_date_hash[:creation_date.gte]
      @groups_upto_count  = ClientGroup.all(hash).count
    elsif @obj.class == Area
      @branches, @centers, @clients = {}, {}, {}
      new_date_hash ||= {}
      upto_date_hash ||= {}
      branch_key = "branch.area_id"
      
      @branches[:new]  = @obj.branches(new_date_hash)
      @branches[:upto] = @obj.branches(upto_date_hash)

      @centers[:new]  = Center.all(new_date_hash.merge({branch_key => @obj.id}))
      @centers[:upto] = Center.all(upto_date_hash.merge({branch_key => @obj.id}))

      @clients[:new]  = Client.all(client_hash(:new).merge({"center.#{branch_key}" => @obj.id, :fields => [:id]}))
      @clients[:upto] = Client.all(client_hash(:upto).merge({"center.#{branch_key}" => @obj.id, :fields => [:id]}))

      hash = {"center.#{branch_key}" => @obj.id}
      hash["center.creation_date.lte"] = new_date_hash[:creation_date.lte] if new_date_hash[:creation_date.lte]
      hash["center.creation_date.gte"] = new_date_hash[:creation_date.gte] if new_date_hash[:creation_date.gte]

      @groups_new_count   = ClientGroup.all(hash).count
      hash["center.creation_date.lte"] = upto_date_hash[:creation_date.gte] if upto_date_hash[:creation_date.gte]
      @groups_upto_count  = ClientGroup.all(hash).count
    elsif @obj.class == Branch
      @centers        = {}
      @centers[:new]  = @obj.centers(new_date_hash)
      @centers[:upto] = @obj.centers(upto_date_hash)
    elsif @obj.class  ==  Center
      @centers        = {}
      @centers[:new] = @centers[:upto] = Center.all(:id =>@obj.id)
    elsif @obj.class == LoanProduct
      @regions, @areas, @branches, @centers, @clients = {}, {}, {}, {}, {}
      @regions[:new]  = LoanHistory.parents_where_loans_of(Region, {:loan => {:loan_product_id => @obj.id}, :region => new_date_hash})
      @regions[:upto] = LoanHistory.parents_where_loans_of(Region, {:loan => {:loan_product_id => @obj.id}, :region => upto_date_hash})

      @areas[:new]  = LoanHistory.parents_where_loans_of(Area, {:loan => {:loan_product_id => @obj.id}, :area => new_date_hash})
      @areas[:upto] = LoanHistory.parents_where_loans_of(Area, {:loan => {:loan_product_id => @obj.id}, :area => upto_date_hash})

      @branches[:new]  = LoanHistory.parents_where_loans_of(Branch, {:loan => {:loan_product_id => @obj.id}, :branch => new_date_hash})
      @branches[:upto] = LoanHistory.parents_where_loans_of(Branch, {:loan => {:loan_product_id => @obj.id}, :branch => upto_date_hash})

      new_center_ids  = LoanHistory.parents_where_loans_of(Center, {:loan => {:loan_product_id => @obj.id}, :center => new_date_hash})
      upto_center_ids = LoanHistory.parents_where_loans_of(Center, {:loan => {:loan_product_id => @obj.id}, :center => upto_date_hash})
      @centers[:new]  = Center.all(:id => new_center_ids) if new_center_ids.length > 0
      @centers[:upto] = Center.all(:id => upto_center_ids) if upto_center_ids.length > 0

      @clients[:new]  = LoanHistory.parents_where_loans_of(Client, {:loan => {:loan_product_id => @obj.id}, :client => client_hash(:new)})
      @clients[:upto] = LoanHistory.parents_where_loans_of(Client, {:loan => {:loan_product_id => @obj.id}, :client => client_hash(:upto)})
    elsif @obj.class == FundingLine
      @regions, @areas, @branches, @centers, @clients = {}, {}, {}, {}, {}
      @regions[:new]  = LoanHistory.parents_where_loans_of(Region, {:loan => {:funding_line_id => @obj.id}, :region => new_date_hash})
      @regions[:upto] = LoanHistory.parents_where_loans_of(Region, {:loan => {:funding_line_id => @obj.id}, :region => upto_date_hash})

      @areas[:new]  = LoanHistory.parents_where_loans_of(Area, {:loan => {:funding_line_id => @obj.id}, :area => new_date_hash})
      @areas[:upto] = LoanHistory.parents_where_loans_of(Area, {:loan => {:funding_line_id => @obj.id}, :area => upto_date_hash})
      
      @branches[:new]  = @obj.branches(new_date_hash)
      @branches[:upto] = @obj.branches(upto_date_hash)

      @centers[:new]  = @obj.centers(new_date_hash)
      @centers[:upto] = @obj.centers(new_date_hash)

      @clients[:new]  = @obj.clients(client_hash(:new))
      @clients[:upto] = @obj.clients(client_hash(:upto))
    elsif @obj.class == StaffMember
      @areas     = @obj.areas
      @branches, @centers, @clients, @loans = {}, {}, {}, {}

      owner_type = (params[:type] and params[:type] == "managed" ? :managed : :created)

      @branches[:new]  = @obj.branches(new_date_hash)
      @branches[:upto] = @obj.branches(upto_date_hash)
      
      @centers[:new]   = @obj.centers(new_date_hash)
      @centers[:upto]  = @obj.centers(upto_date_hash)

      @clients[:new]  = @obj.clients(client_hash(:new), owner_type)
      @clients[:upto] = @obj.clients(client_hash(:upto), owner_type)

      if owner_type == :created
        @groups_new_count  = ((@clients[:new] and @clients[:new].count > 0) ? @clients[:new].client_groups(:created_by_staff => @obj).count : 0)
        @groups_upto_count = ((@clients[:upto] and @clients[:upto].count > 0) ? @clients[:upto].client_groups(:created_by_staff => @obj).count : 0)
      end
    else
      raise "Unknown obj class"
    end

    if @areas and not @branches
      @branches        = {}
      @branches[:new]  = (@areas.class == Hash ? @areas[:upto] : @areas).branches(new_date_hash)
      @branches[:upto] = (@areas.class == Hash ? @areas[:upto] : @areas).branches(upto_date_hash)
    end

    if @branches and not @centers
      @centers   = {}
      @centers[:new]   = (@branches.class == Hash ? @branches[:upto] : @branches).centers(new_date_hash)
      @centers[:upto]   = (@branches.class == Hash ? @branches[:upto] : @branches).centers(upto_date_hash)
    end
    
    unless @clients 
      @clients        = {}
      if (@centers.class == Hash) and (@centers[:upto].count == 0)
        @clients[:new] = 0
        @clients[:upto] = 0
      else
        @clients[:new]  = (@centers.class == Hash ? @centers[:upto] : @centers).clients(client_hash(:new) + {:fields => [:id]})
        @clients[:upto] = (@centers.class == Hash ? @centers[:upto] : @centers).clients(client_hash(:upto) + {:fields => [:id]})
      end
    end

    set_more_info(@obj, owner_type||:managed)
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
    @clients_without_insurance = (@client_ids - InsurancePolicy.all(:fields => [:id, :client_id]).map{|x| x.client_id}).length
    render :file => 'info/exceptions', :layout => false
  end

private
  def set_info_form_params
    @render_form = true
    @render_form = false if params[:_target_]
    @from_date = params[:from_date] ? parse_date(params[:from_date]) : Date.min_date
    @to_date   = params[:to_date]   ? parse_date(params[:to_date])   : Date.today
    if params[:from_date]
      return [{:creation_date.lte => @to_date, :creation_date.gte => @from_date}, {:creation_date.lte => @to_date}]
    else
      return {}
    end
  end

  def client_hash(type)
    if params[:from_date] and type == :new
      return {:date_joined.lte => @to_date, :date_joined.gte => @from_date}
    elsif params[:from_date] and type == :upto
      return {:date_joined.lte => @to_date}
    else
      return {}
    end
  end

  def set_more_info(obj, child_type = :managed)
    @centers_new_count  = @centers.key?(:new) ? @centers[:new].count : 0
    @centers_upto_count = @centers.key?(:upto) ? @centers[:upto].count : 0

    unless @groups_new_count
      @groups_new_count  = (@centers_new_count  > 0 and @centers[:new]) ? @centers[:new].client_groups(:fields => [:id]).count : 0
    end
    
    unless @groups_upto_count
      @groups_upto_count = (@centers_upto_count > 0 and @centers[:upto] and not @groups_upto_count) ? @centers[:upto].client_groups(:fields => [:id]).count : 0
    end

    unless @clients_new_count
      @clients_new_count  = (@clients and @clients[:new]) ?  (@clients[:new].is_a?(Array) ? @clients[:new].count : 0) : 0
    end
    
    unless @clients_upto_count
      @clients_upto_count = (@clients and @clients[:upto]) ? (@clients[:upto].is_a?(Array) ? @clients[:upto].count : 0) : 0
    end

    @payments        = Payment.collected_for(obj, @from_date, @to_date, [1, 2], child_type)
    @total_payments  = Payment.collected_for(obj, Date.min_date, @to_date, [1, 2], child_type)
    @fees            = Fee.collected_for(obj, @from_date, @to_date, child_type)
    @total_fees      = Fee.collected_for(obj, Date.min_date, @to_date, child_type)

    if LoanHistory.count > 0
      @total_disbursed = LoanHistory.amount_disbursed_for(obj, Date.min_date, @to_date, child_type)
      @loan_disbursed  = LoanHistory.amount_disbursed_for(obj, @from_date, @to_date, child_type)

      @loan_data       = LoanHistory.sum_outstanding_for(obj, @to_date, child_type)
      @defaulted       = LoanHistory.defaulted_loan_info_for(obj, @to_date, nil, :aggregate, child_type)
      # @total_death_cases = Client.death_cases(obj,Date.min_date,@to_date)  
      # @death_cases = Client.death_cases(obj,@from_date,@to_date) 
      # @pending_death_cases = Client.pending_death_cases(obj,@from_date,@to_date)
      @loans_repaid  = LoanHistory.loan_repaid_count(obj,@from_date, @to_date, child_type)
      @loans_repaid_total =  LoanHistory.loan_repaid_count(obj,Date.min_date, @to_date, child_type)
    else
      @total_disbursed = @loan_disbursed = @loan_data = @defaulted = @loans_repaid = @loans_repaid_total = 0
    end
  end
end
