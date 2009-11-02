class Dashboard < Application
  before :ensure_has_mis_manager_privileges

  def index
    render
  end

  def today
    @date = params[:date].blank? ? Date.today : Date.parse(params[:date])
    render
  end
  
end
