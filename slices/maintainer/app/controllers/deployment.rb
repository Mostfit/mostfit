class Maintainer::Deployment < Maintainer::Application

  include Merb::Maintainer::TasksHelper
  before :initialize_repo

  def index
    @branches = @git.branches.local.map(&:full)
    @current_branch = @git.current_branch
    render :layout => false
  end

  def deploy
    deploy_code(params)
    (request.xhr?) ? (return "true") : redirect('/maintain#deployment')
  end

  def rollback
    rollback_code(params)
    (request.xhr?) ? (return "true") : redirect("/maintain#deployment")
  end

  def check_if_deployment_possible
    (request.xhr?) ? (return deployable?) : redirect("/maintain#deployment")
  end

  private
  def initialize_repo
    @git = Git.open(GIT_REPO)
  end

end
