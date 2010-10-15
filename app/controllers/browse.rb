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
    center_ids = LoanHistory.all(:date => @date).map{|x| x.center_id}.uniq
        # restrict branch manager and center managers to their own branches
    if session.user.role==:staff_member
      st = session.user.staff_member
      center_ids = ([st.branches.centers.map{|x| x.id}, st.centers.map{|x| x.id}].flatten.compact) & center_ids
    end
    
    center_ids = ["NULL"] if center_ids.length==0
    center_ids = center_ids.join(',')
    client_ids = repository.adapter.query(%Q{SELECT c.id FROM clients c WHERE c.center_id IN (#{center_ids})})
    @data = repository.adapter.query(%Q{SELECT c.id as id, c.branch_id as branch_id, c.name name, SUM(lh.principal_due) pd, SUM(lh.interest_due) intd, 
                                                   SUM(lh.principal_paid) pp, SUM(lh.interest_paid) intp
                                        FROM loan_history lh, centers c
                                        WHERE lh.center_id IN (#{center_ids}) AND lh.date='#{@date.strftime('%Y-%m-%d')}' AND c.id=lh.center_id
                                        GROUP BY lh.center_id ORDER BY c.name}).group_by{|x| Branch.get(x.branch_id)}
    @disbursals = Loan.all(:client_id => client_ids, :scheduled_disbursal_date => @date)
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
