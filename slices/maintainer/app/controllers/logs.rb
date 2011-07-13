class Maintainer::Logs < Maintainer::Application

  def index
    @watchable_files = WATCHABLE_FILES
    render :layout => false
  end

  def get
    file = params[:file]
    is_first_request = params[:is_first_request]
    @response = get_log(file, is_first_request)
  end

end
