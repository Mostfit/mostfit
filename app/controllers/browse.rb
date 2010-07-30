class Browse < Application
  before :before

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

end
