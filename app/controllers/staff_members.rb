class StaffMembers < Application
  include Pdf::DaySheet if PDF_WRITER
  include DateParser
  layout :determine_layout

  def index
    per_page = 25
    if params[:date].is_a? Hash
      @date = Date.new(params[:date][:year].to_i, params[:date][:month].to_i, params[:date][:day].to_i)
    else
      @date = params[:date] ? Date.parse(params[:date]) : Date.today
    end
    @staff_members = if params[:branch_id] and not params[:branch_id].blank?
                       @branch = Branch.get(params[:branch_id])
                       StaffMember.all(:id => ([@branch.manager.id] << @branch.centers.manager.map{|x| x.id}).flatten.uniq).paginate(:page => params[:page], 
                                                                                                                                             :per_page => per_page)
                     else
                       StaffMember.paginate(:page => params[:page], :per_page => per_page)
                     end
    first_of_this_month     = Date.new(@date.year, @date.month, 1)
    @branch_managers_overall   = Branch.aggregate(:manager_staff_id, :all.count)
    @branch_managers_thismonth = Branch.all(:creation_date.gte => first_of_this_month).aggregate(:manager_staff_id, :all.count)

    @center_managers_overall   = Center.aggregate(:manager_staff_id, :all.count)
    @center_managers_thismonth = Center.all(:creation_date.gte => first_of_this_month).aggregate(:manager_staff_id, :all.count)

    @applied_loans_overall     = Loan.aggregate(:applied_by_staff_id, :all.count)
    @applied_loans_thismonth   = Loan.all(:applied_on.gte => first_of_this_month).aggregate(:applied_by_staff_id, :all.count)

    @approved_loans_overall    = Loan.aggregate(:approved_by_staff_id, :all.count)
    @approved_loans_thismonth  = Loan.all(:approved_on.gte => first_of_this_month).aggregate(:approved_by_staff_id, :all.count)

    @rejected_loans_overall    = Loan.aggregate(:rejected_by_staff_id, :all.count)
    @rejected_loans_thismonth  = Loan.all(:rejected_on.gte => first_of_this_month).aggregate(:rejected_by_staff_id, :all.count)

    @disbursed_loans_overall   = Loan.aggregate(:disbursed_by_staff_id, :all.count)
    @disbursed_loans_thismonth = Loan.all(:disbursal_date.gte => first_of_this_month).aggregate(:disbursed_by_staff_id, :all.count)

    @writtenoff_loans_overall  = Loan.aggregate(:written_off_by_staff_id, :all.count)
    @writtenoff_loans_thismonth= Loan.all(:written_off_on.gte => first_of_this_month).aggregate(:written_off_by_staff_id, :all.count)

    display @staff_members
  end

  def show_centers(id)
    @staff_member = StaffMember.get(id)
    raise NotFound unless @staff_member
    @centers = @staff_member.centers
    display @centers
  end

  def show_clients(id)
    @staff_member = StaffMember.get(id)
    raise NotFound unless @staff_member
    @clients = @staff_member.centers.clients
    display @clients
  end

  def show_disbursed(id)
    @staff_member = StaffMember.get(id)
    raise NotFound unless @staff_member
    @loans = @staff_member.disbursed_loans
    display @loans
  end

  def day_sheet(id)
    @staff_member = StaffMember.get(id)
    raise NotFound unless @staff_member
    @date      = params[:date] ? parse_date(params[:date]) : Date.today
    days       = []
    days      << Center.meeting_days[@date.cwday]
    @date      = @date.holiday_bump
    days      << Center.meeting_days[@date.cwday]
    @centers   = @staff_member.centers.all(:meeting_day => days.uniq).sort_by{|x| x.name}
    if params[:format] == "pdf"
      generate_pdf
      send_data(File.read("#{Merb.root}/public/pdfs/staff_#{@staff_member.id}_#{@date}.pdf"),
                :filename => "#{Merb.root}/public/pdfs/staff_#{@staff_member.id}_#{@date}.pdf")
    else
      display @centers
    end
  end

  def show(id)
    @staff_member = StaffMember.get(id)
    raise NotFound unless @staff_member
    display @staff_member
  end

  def new
    only_provides :html
    @staff_member = StaffMember.new
    display @staff_member
  end

  def edit(id)
    only_provides :html
    @staff_member = StaffMember.get(id)
    raise NotFound unless @staff_member
    display @staff_member
  end

  def create(staff_member)
    @staff_member = StaffMember.new(staff_member)
    if @staff_member.save
      redirect resource(:staff_members), :message => {:notice => "StaffMember was successfully created"}
    else
      message[:error] = "StaffMember failed to be created"
      render :new
    end
  end

  def update(id, staff_member)
    @staff_member = StaffMember.get(id)
    raise NotFound unless @staff_member
    if @staff_member.update_attributes(staff_member)
       redirect resource(:staff_members)
    else
      display @staff_member, :edit
    end
  end

  def destroy(id)
    @staff_member = StaffMember.get(id)
    raise NotFound unless @staff_member
    if @staff_member.destroy
      redirect resource(:staff_members)
    else
      raise InternalServerError
    end
  end

  private
  def determine_layout
    return "printer" if params[:layout] and params[:layout]=="printer"
  end
end # StaffMembers
