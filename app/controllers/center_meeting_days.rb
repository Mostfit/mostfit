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
  
  def new
    @center = Center.get(params[:center_id])
    @cmd = CenterMeetingDay.new(:center => @center)
    render
  end
  
  def create(center_meeting_day)
    @center = Center.get(params[:center_id])
    @cmd = CenterMeetingDay.new(center_meeting_day)
    @cmd.center = @center
    @cmd.valid_from = @center.creation_date if @cmd.valid_from.blank?
    @cmd.valid_upto = Date.new(2100,12,31) if @cmd.valid_upto.blank?
    @cmd.every = "1" unless @cmd.every
    @cmd.of_every = 1 unless @cmd.of_every
    if @cmd.save
      redirect resource(@center, :center_meeting_days), :message => {:success => "Center Meeting Day created"}
    else
      render :new
    end
  end
  
  
  def update(id, center_meeting_day)
    debugger
    center_meeting_day[:valid_from] = Date.parse(center_meeting_day[:valid_from])
    center_meeting_day[:valid_upto] = Date.parse(center_meeting_day[:valid_upto])
    @cmd = CenterMeetingDay.get(id)
    @cmd.update(center_meeting_day)
    if @cmd.save
      redirect resource(@cmd.center, :center_meeting_days), :message => {:success => "Center Meeting Day updated"}
    else
      render :edit
    end
  end
  
  
end
