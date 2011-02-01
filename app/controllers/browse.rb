class Browse < Application
  before :get_centers_and_template
  before :display_from_cache, :only => [:hq_tab]
  after  :store_to_cache,     :only => [:hq_tab]
  
  def index
    render :template => @template
  end

  def branches
    redirect resource(:branches)
  end

  def centers
    if session.user.role == :staff_member
      @centers = Center.all(:manager => session.user.staff_member, :order => [:meeting_day]).paginate(:per_page => 15, :page => params[:page] || 1)
    else
      @centers = Center.all.paginate(:per_page => 15, :page => params[:page] || 1)
    end
    @branch =  @centers.branch[0]
    render :template => 'centers/index'
  end

  def hq_tab
    partial :totalinfo
  end

  def centers_paying_today
    @date = params[:date] ? Date.parse(params[:date]) : Date.today
    hash  = {:date => @date}
    hash  = {:branch_id => params[:branch_id]} if params[:branch_id] and not params[:branch_id].blank?
    center_ids = LoanHistory.all(hash).aggregate(:center_id)
    loans      = LoanHistory.all(hash).aggregate(:loan_id, :center_id).to_hash

    # restrict branch manager and center managers to their own branches
    if user = session.user and staff = user.staff_member
      hash[:branch_id] = [staff.related_branches.map{|x| x.id}, staff.centers.branches.map{|x| x.id}].uniq
      center_ids = staff.related_centers.map{|x| x.id} & center_ids
    end
    
    if Mfi.first.map_enabled
      @locations = Location.all(:parent_id => center_ids, :parent_type => "center").group_by{|x| x.parent_id}
    end

    @overdues = LoanHistory.defaulted_loan_info_by(:center, @date-1, {:center_id => center_ids}).group_by{|x| x.center_id}

    @fees_due, @fees_paid, @fees_overdue  = Hash.new(0), Hash.new(0), Hash.new(0)
    Fee.applicable(loans.keys, {:date => @date}).each{|fa|
      @fees_due[loans[fa.loan_id]] += fa.fees_applicable
    }
    Payment.all(:type => :fees, "client.center_id" => center_ids).aggregate(:loan_id, :amount.sum).each{|fp|
      @fees_due[loans[fp[0]]] -= fp[1]
    }
    
    Payment.all(:type => :fees, :received_on => @date, "client.center_id" => center_ids).aggregate(:loan_id, :amount.sum).each{|fp|
     @fees_paid[loans[fp[0]]] += fp[1]
    }

    Fee.applicable(loans.keys, {:date => @date-1}).each{|fa|
      @fees_overdue[loans[fa.loan_id]] += fa.fees_applicable
    }
    
    @disbursals = Loan.all("client.center_id" => center_ids, :scheduled_disbursal_date => @date)
    
    @data = LoanHistory.all(:date => @date, :center_id => center_ids, 
                            :status => [:disbursed, :outstanding]).aggregate(:branch_id, :center_id, :principal_due.sum, :interest_due.sum,                                                                             
                                                                             :principal_paid.sum, :interest_paid.sum).group_by{|x|
      x[0]
    }
    @centers  = Center.all(:id => center_ids)
    @branches = @centers.branches.map{|b| [b.id, b.name]}.to_hash
    @centers  = @centers.map{|c| [c.id, c]}.to_hash
    
    center_ids = ["NULL"] if center_ids.length==0
    center_ids = center_ids.join(',')
    @advances = LoanHistory.sum_advance_payment(@date, @date, :center, ["center_id in (#{center_ids})"]).group_by{|x| x.center_id}
    render :template => 'dashboard/today'
  end

  private
  def get_centers_and_template
    if session.user.staff_member
      @staff ||= session.user.staff_member
      if branch = Branch.all(:manager => @staff)
        true
      else
        @centers = Center.all(:manager => @staff)
        @template = 'browse/for_staff_member'
      end
    end
  end

end
