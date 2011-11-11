class CenterMeetingDays < Application

  def index
    @center = Center.get(params[:center_id])
    @center_meeting_days = @center.center_meeting_days
    display @center_meeting_days
  end
  
  def edit(id)
    @cmd = CenterMeetingDay.get(params[:id])
    raise NotFound unless @cmd
    display @cmd
  end
  
  def update(center_meeting_day)
    @cmd = CenterMeetingDay.get(params[:id])
    raise NotFound unless @cmd
    @cmd.update(center_meeting_day)
    redirect resource(@cmd), :message => {:notice => "Success!"}
  end
  
  def new
    @center = Center.get(params[:center_id])
    @cmd = CenterMeetingDay.new(:center => @center)
    render
  end
  
  def create(center_meeting_day)
    @center = Center.get(params[:center_id])
    @cmd = CenterMeetingDay.new(center_meeting_day)
    @cmd.center = @center
    debugger
    if @cmd.save
      redirect resource(@center, :center_meeting_days), :message => {:success => "Center Meeting Day updated"}
    else
      render :new
    end
  end
  
  
  def update(id, center_meeting_day)
    center_meeting_day[:valid_from] = Date.parse(center_meeting_day[:valid_from])
    center_meeting_day[:valid_upto] = Date.parse(center_meeting_day[:valid_upto])
    @cmd = CenterMeetingDay.get(id)
    @cmd.update(center_meeting_day)
    if @cmd.save
      redirect resource(@cmd.center, :center_meeting_days), :message => {:success => "Center Meeting Day updated"}
    else
      render
    end
  end
  
  
end
