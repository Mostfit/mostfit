class Attendances < Application
  
  before :get_context

  def index
    @attendances = @client.attendances
    if request.xhr?
      partial "attendances/index"
    else
      render
    end
  end

  private
  def get_context
    @client = Client.get(params[:client_id]) if params[:client_id]
  end
  
end
