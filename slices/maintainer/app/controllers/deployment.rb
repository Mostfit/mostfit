class Maintainer::Deployment < Maintainer::Application
  def index
    render :layout => false
  end
end
