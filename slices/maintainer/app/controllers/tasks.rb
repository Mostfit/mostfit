class Maintainer::Tasks < Maintainer::Application

  before :initialize_crontab, :only => [:create,:edit,:update,:delete]

  def index
    render :layout => false
  end

  def new
    render :layout => false
  end

  def create
    schedule = create_schedule params

    params["tasks"].each{|task|
      output_file = "$HOME/cron.log 2>&1"
      schedule[:command] = "cd #{Merb.root}; $HOME/.rvm/bin/rvm gemset list >> #{output_file}; $HOME/.rvm/rubies/$RUBY_VERSION/bin/gem list >> #{output_file}; #{task} >> #{output_file}"
      index = (@crontab.list_maintainer.length > 0) ? (@crontab.list_maintainer.keys.sort.last[/\d+/].to_i + 1) : 1
      @crontab.add("maintainer_#{index}", schedule)
      @crontab.commit
    }
    redirect("/maintain#tasks")
  end

  def edit
    @task_name = params[:task]
    @task = @crontab.list_maintainer[@task_name].to_cron_entry
    render :layout => false
  end

  def update
    schedule = create_schedule params
    schedule[:command] = params["task_command"]
    @crontab.add(params["task_name"], schedule)
    @crontab.commit
    redirect("/maintain#tasks")
  end

  def delete
    @crontab.remove(params[:task])
    @crontab.commit
    redirect("/maintain#tasks")
  end

  private
  def initialize_crontab
    @crontab = CronEdit::Crontab.new(`echo $USER`.chomp)
  end

  def create_schedule(params)
    schedule = {
      :minute => (params["minutes-selected"] == "0") ?  "*" : params["minute"].join(","),
      :hour => (params["hours-selected"] == "0") ?  "*" : params["hour"].join(","),
      :day => (params["days-selected"] == "0") ?  "*" : params["day"].join(","),
      :month => (params["months-selected"] == "0") ?  "*" : params["month"].join(","),
      :weekday => (params["weekdays-selected"] == "0") ?  "*" : params["weekday"].join(",")
    }
  end

end
