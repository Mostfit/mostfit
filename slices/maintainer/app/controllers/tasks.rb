class Maintainer::Tasks < Maintainer::Application

  before :initialize_crontab, :only => [:create,:edit,:update,:delete]

  def index
    render :layout => false
  end

  def new
    render :layout => false
  end

  def create
    create_task(params)
    (request.xhr?) ? (return "true") : redirect("/maintain#tasks")
  end

  def edit
    @task_name = params[:task]
    @task = @crontab.list_maintainer[@task_name].to_task
    render :layout => false
  end

  def update
    update_task(params)
    (request.xhr?) ? (return "true") : redirect("/maintain#tasks")
  end

  def delete
    delete_task(params)
    (request.xhr?) ? (return "true") : redirect("/maintain#tasks")
  end

  private
  def initialize_crontab
    @crontab = CronEdit::Crontab.new(`echo $USER`.chomp)
  end

end
