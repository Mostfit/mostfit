class Maintainer::Logs < Maintainer::Application

  def index
    @watchable_files = get_parsed_watchable_files
    render :layout => false
  end

  def get
    file = params[:file]
    max_line_count = params[:max_line_count].to_i
    is_first_request = params[:is_first_request]
    @response = get_log(file, max_line_count, is_first_request)
  end

end
