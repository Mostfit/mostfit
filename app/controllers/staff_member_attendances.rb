class StaffMemberAttendances < Application

  before :get_context, :exclude => ['redirect_to_show']
  provides :xml #, :yaml, :js

  def index
    if request.xhr?
      @staff_member_attendances = @staff_member.staff_member_attendances.paginate(:page => params[:page], :per_page => 20)
      partial "staff_member_attendances/index"
    else
      render
    end
  end

  # def show(id)
  #   @staff_member_attendance = StaffMemberAttendance.get(id)
  #   raise NotFound unless @staff_member_attendance
  #   display @staff_member_attendance
  # end

  def new
    only_provides :html
    @staff_member_attendance = StaffMemberAttendance.new
    display @staff_member_attendance
  end

  def edit(id)
    @staff_member_attendance = StaffMemberAttendance.get(id)
    raise NotFound unless @staff_member_attendance
    display @staff_member_attendance
  end

  def create(staff_member_attendance)
    @staff_member_attendance = StaffMemberAttendance.new(staff_member_attendance)
    @staff_member_attendance.staff_member_id = params[:staff_member_attendance][:staff_member_id]
    if @staff_member_attendance.save
      redirect(params[:return] || resource(@staff_member_attendance.staff_member), :message => {:notice => "Attendance was recorded successfully"})
    else
      redirect(params[:return] || resource(@staff_member_attendance.staff_member),
               :message => {:error => "Attendance could not be recorded because : #{@staff_member_attendance.errors.instance_variable_get("@errors").map{|k, v| v.join(", ")}.join(", ")}"})
    end
  end

  def update(id, staff_member_attendance)
    @staff_member_attendance = StaffMemberAttendance.get(id)
    raise NotFound unless @staff_member_attendance
    if @staff_member_attendance.update(staff_member_attendance)
      redirect(params[:return] || resource(@staff_member_attendance.staff_member), :message => {:notice => "Attendance of #{@staff_member_attendance.date} was updated successfully"})
    else
      redirect(params[:return] || resource(@staff_member_attendance.staff_member),
               :message => {:error => "Attendance could not be updated because : #{@staff_member_attendance.errors.instance_variable_get("@errors").map{|k, v| v.join(", ")}.join(", ")}"})
    end
  end

  def destroy(id)
    @staff_member_attendance = StaffMemberAttendance.get(id)
    raise NotFound unless @staff_member_attendance
    if @staff_member_attendance.destroy
      redirect(params[:return] || resource(@staff_member_attendance.staff_member), :message => {:notice => "Attendance was deleted successfully"})
    else
      redirect(params[:return] || resource(@staff_member_attendance.staff_member),
               :message => {:error => "Attendance could not be deleted because : #{@staff_member_attendance.errors.instance_variable_get("@errors").map{|k, v| v.join(", ")}.join(", ")}"})
    end
  end

  def delete(id)
    @staff_member_attendance = StaffMemberAttendance.get(id)
    raise NotFound unless @staff_member_attendance
    if @staff_member_attendance.destroy
      redirect(params[:return] || resource(@staff_member), :message => {:notice => "Attendance of #{@staff_member_attendance.date} was deleted successfully"})
    else
      redirect(params[:return] || resource(@staff_member_attendance.staff_member),
               :message => {:error => "Attendance could not be deleted because : #{@staff_member_attendance.errors.instance_variable_get("@errors").map{|k, v| v.join(", ")}.join(", ")}"})
    end
  end

  # this redirects to the proper url, used from the router
  def redirect_to_show(id)
    raise NotFound unless @staff_member_attendance = StaffMemberAttendance.get(id)
    if @staff_member_attendance.staff_member
      redirect resource(@staff_member_attendance.staff_member)
    else
      redirect resource(@staff_member)
    end
  end

  private
  def get_context
    @staff_member = StaffMember.get(params[:staff_member_id]) if params[:staff_member_id]
  end

end # StaffMemberAttendances
