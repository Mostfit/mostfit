class Admin < Application
  before :ensure_has_admin_privileges

  def index
    render
  end
  
end
