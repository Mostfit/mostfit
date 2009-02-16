class Application < Merb::Controller
  before :ensure_authenticated

  def ensure_has_mis_manager_privileges
    raise NotPrivileged unless session.user.mis_manager? || session.user.admin?
  end

  def ensure_has_admin_privileges
    raise NotPrivileged unless session.user.admin?
  end

end
