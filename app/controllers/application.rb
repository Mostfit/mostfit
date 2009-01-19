class Application < Merb::Controller
  before :ensure_authenticated
end