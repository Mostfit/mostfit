class StaffMembers < Application
  include Pdf::DaySheet if PDF_WRITER
  include DateParser
  layout :determine_layout

  def index
    per_page = 25
    @date = params[:date] ? parse_date(params[:date]) : Date.today

    hash = get_staff_members_hash
    @staff_members = StaffMember.all(hash).paginate(:page => params[:page], :per_page => per_page)
    set_staff_member_counts

    display @staff_members
  end

  #serves info tab for staff member
  def moreinfo(id)
    @render_form = true
    @render_form = false if params[:_target_]
    @from_date   = params[:from_date] ? parse_date(params[:from_date]) : Date.min_date
    @to_date     = params[:to_date]   ? parse_date(params[:to_date])   : Date.today
    allow_nil    = (params[:from_date] or params[:to_date]) ? false : true
    @staff_member= StaffMember.get(id)
    raise NotFound unless @staff_member

    if allow_nil
      @clients       = @center.clients(:fields => [:id])
    else
      @clients       = @center.clients(:fields => [:id], :date_joined.lte => @to_date, :date_joined.gte => @from_date)
    end

    @groups_count  = @center.client_groups(:fields => [:id]).count
    @clients_count = @clients.count
    @payments      = Payment.collected_for(@center, @from_date, @to_date)
    @fees          = Fee.collected_for(@center, @from_date, @to_date)
    @loan_disbursed= LoanHistory.amount_disbursed_for(@center, @from_date, @to_date)
    @loan_data     = LoanHistory.sum_outstanding_for(@center, @from_date, @to_date)
    @defaulted     = LoanHistory.defaulted_loan_info_for(@center, @to_date)
    render :file => 'branches/moreinfo', :layout => false
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
    @date     = @date.holiday_bump
    days       = []
    days      << Center.meeting_days[@date.cwday]
    days      << Center.meeting_days[@date.holidays_shifted_today.cwday]
    @centers   = @staff_member.centers.all(:meeting_day => days.uniq).sort_by{|x| x.name}
    if params[:format] == "pdf"
      generate_pdf
      send_data(File.read("#{Merb.root}/public/pdfs/staff_#{@staff_member.id}_#{@date.strftime('%Y_%m_%d')}.pdf"),
                :filename => "#{Merb.root}/public/pdfs/staff_#{@staff_member.id}_#{@date.strftime('%Y_%m_%d')}.pdf")
    else
      display @centers
    end
  end

  def show(id)
    @staff_member = StaffMember.get(id)
    raise NotFound unless @staff_member
    @manages = {:regions => @staff_member.regions, :areas => @staff_member.areas, :branches => @staff_member.branches, :centers => @staff_member.centers}
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
  
  def get_staff_members_hash
    if session.user.role == :staff_member
      st = session.user.staff_member
      ids = []
      [st.branches, st.centers.branches].flatten.uniq.each{|branch|        
        staff_members = StaffMember.related_to(branch)
        ids += ([staff_members, branch.manager.id] << branch.centers.manager.map{|x| x.id}).flatten.uniq        
      }
      return {:id => ids}
    elsif params[:branch_id] and not params[:branch_id].blank?
      branch = Branch.get(params[:branch_id])
      staff_members = StaffMember.related_to(branch)
      ids = ([staff_members, branch.manager.id] << branch.centers.manager.map{|x| x.id}).flatten.uniq
      return {:id => ids}
    else
      return {}
    end
  end

  def set_staff_member_counts
    first_of_this_month = Date.new(@date.year, @date.month, 1)
    end_of_this_month   = @date

    { 
      :branch_managers => Branch, :center_managers => Center, :applied_loans => Loan, :approved_loans => Loan, 
      :rejected_loans  => Loan, :disbursed_loans => Loan, :written_off_loans => Loan
    }.each{|type, klass|
      if klass==Branch or klass==Center
        aggregate_by   = :manager_staff_id
        overall_cond   = {:creation_date.lte => @date}
        thismonth_cond = {:creation_date.lte => @date, :creation_date.gte => first_of_this_month}
      else
        name           = (type.to_s.split('_')-["loans"]).join("_")
        aggregate_by   = (name + "_by_staff_id").to_sym
        date_key       = name=="disbursed" ? :disbursal_date : (name+"_on").to_sym
        overall_cond   = {date_key.lte => @date}
        thismonth_cond = {date_key.lte => @date, date_key.gte => first_of_this_month}
      end
      
      instance_variable_set("@#{type}_overall",   klass.all(overall_cond).aggregate(aggregate_by, :all.count))
      instance_variable_set("@#{type}_thismonth", klass.all(thismonth_cond).aggregate(aggregate_by, :all.count))      
    }
  end
end # StaffMembers
