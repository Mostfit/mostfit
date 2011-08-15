module Merb::Maintainer::TasksHelper

  # create a scheduled task based on the information in 'params'
  def create_task(params)
    schedule = create_schedule(params)

    output_stream = CRON_LOG + " 2>&1"
    task = params['task']
    schedule[:command] = "/bin/bash -l -c 'cd #{Merb.root}; #{task} >> #{output_stream}'"

    index = (@crontab.list_maintainer.length > 0) ? (@crontab.list_maintainer.keys.sort.last[/\d+/].to_i + 1) : 1
    @crontab.add("maintainer_#{index}", schedule)
    @crontab.commit

    log({
      :action => 'created_task',
      :ip     => request.remote_ip,
      :name   => params["task"]
    })
  end

  # update the specified scheduled task using the information in 'params'
  def update_task(params)
    schedule = create_schedule(params)
    schedule[:command] = params["task_command"]
    @crontab.add(params["task_name"], schedule)
    @crontab.commit
    log({
      :action => 'edited_task',
      :ip     => request.remote_ip,
      :name   => @crontab.list_maintainer[params["task_name"]].to_task[:rake_task]
    })
  end

  # delete the specified task
  def delete_task(params)
    task = @crontab.list_maintainer[params[:task]].to_task[:rake_task]
    @crontab.remove(params[:task])
    @crontab.commit
    log({
      :action => 'deleted_task',
      :ip     => request.remote_ip,
      :name   => task
    })
  end

  private
  # creates a schedule hash using information in params (used to parse schedule form data from the view side)
  def create_schedule(params)
    schedule = case params["schedule-type"]
    when "simple"
      case params["schedule-simple"]
      when "hourly"  then {:minute => "0", :hour => "*", :day => "*", :month => "*", :weekday => "*"}
      when "daily"   then {:minute => "0", :hour => "0", :day => "*", :month => "*", :weekday => "*"}
      when "weekly"  then {:minute => "0", :hour => "0", :day => "*", :month => "*", :weekday => "0"}
      when "monthly" then {:minute => "0", :hour => "0", :day => "1", :month => "*", :weekday => "*"}
      end
    when "custom"
      {
        :minute => (params["minutes-selected"] == "0") ?  "*" : params["minute"].join(","),
        :hour => (params["hours-selected"] == "0") ?  "*" : params["hour"].join(","),
        :day => (params["days-selected"] == "0") ?  "*" : params["day"].join(","),
        :month => (params["months-selected"] == "0") ?  "*" : params["month"].join(","),
        :weekday => (params["weekdays-selected"] == "0") ?  "*" : params["weekday"].join(",")
      }
    end
    return schedule
  end

  # returns a list of all rake tasks in the mostfit namespace, and creates a (sort of) cache of them in RAKE_TASKS_FILE
  def get_mostfit_rake_tasks
    rake_tasks = {}
    refresh_rake_tasks_file unless File.exists?(RAKE_TASKS_FILE)

    File.open(RAKE_TASKS_FILE) do |f|
      f.readlines.find_all{|t| /^rake mostfit/=~t}.each do |task|
        task_parts = task.split("# ").map(&:strip)
        rake_tasks[task_parts[0]] = task_parts[1]
      end
    end

    rake_tasks
  end

  # refresh the "cache" of mostfit-namespaced rake tasks
  def refresh_rake_tasks_file
    `rake -T mostfit > #{RAKE_TASKS_FILE}`
  end

end
