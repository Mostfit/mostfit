class Maintainer::Admin < Maintainer::Application

  before :get_maintainers

  def index
    render :layout => false
  end

  def new
    render :layout => false
  end
  
  def stop
    `touch tmp/stop.txt`
    render :index, :layout => false
  end

  def start
    `rm tmp/stop.txt`
    render :index, :layout => false
  end


  def create
    ret = create_user
    (request.xhr?) ? ret : redirect("/maintain#admin")
  end

  def change_password
    @user_login = params[:user]
    render :layout => false
  end

  def update_password
    ret = password_update
    (request.xhr?) ? ret : redirect("/maintain#admin")
  end

  def enable
    ret = enable_user
    (request.xhr?) ? ret : redirect("/maintain#admin")
  end

  def disable
    ret = disable_user
    (request.xhr?) ? ret : redirect("/maintain#admin")
  end

  def delete
    ret = delete_user
    (request.xhr?) ? ret : redirect("/maintain#admin")
  end

  private
  def get_maintainers
    @maintainers = User.all(:role => :maintainer)
  end

  def operation_allowed?
    return true if not @maintainers.first(:login => params[:user]).active?
    @operation_allowed = (@maintainers.all(:active => true).count - 1 > 0)
  end

end
