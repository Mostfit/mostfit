class Dashboard < Application
  before :ensure_has_mis_manager_privileges

  def index
    render
  end
  
end
