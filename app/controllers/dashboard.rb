class Dashboard < Application

  def index
    render
  end

  def today
    @date = params[:date].blank? ? Date.today : Date.parse(params[:date])
    render
  end
  
end
