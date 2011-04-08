class Attendances < Application
  
  before :get_context
  provides :xml
  def index
    @attendances = @client.attendances
    if request.xhr?
      partial "attendances/index"
    else
      render
    end
  end
  
  def create(attendance)
    @attendance = Attendance.new(attendance)
    if @attendance.save
      display @attendance
    else
      @error = "Attendance has been failed"
      display @error
    end
  end

  private
  def get_context
    @client = Client.get(params[:client_id]) if params[:client_id]
  end

end
