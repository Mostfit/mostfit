require 'cronedit'

class Array
  def join_human(separator)
    (self.length > 1) ? (self[0..-2].join(separator) + " and " + self[-1]) : (self.first)
  end
end

class String
  def to_task
    parts = self.split("\t")
    task = {
      :minute    => parts[0],
      :hour      => parts[1],
      :day       => parts[2],
      :month     => parts[3],
      :weekday   => parts[4],
      :command   => parts[5],
      :rake_task => parts[5][/rake mostfit:.*? /].strip
    }

    months = Merb::Maintainer::Constants::MONTHS
    weekdays = Merb::Maintainer::Constants::WEEKDAYS
    
    minutes_str = (task[:minute] == "*") ? ("Every minute") : (task[:minute].split(",").map(&:to_i).map(&:ordinalize).join_human(", ")+" minute")
    hours_str = (task[:hour] == "*") ? ("every hour") : (task[:hour].split(",").map(&:to_i).map(&:ordinalize).join_human(", ")+" hour")
    days_str = (task[:day] == "*") ? ("every day") : (task[:day].split(",").map(&:to_i).map(&:ordinalize).join_human(", ")+" day")
    months_str = (task[:month] == "*") ? ("every month") : (task[:month].split(",").map(&:to_i).map {|m| months[m-1] }.join_human(", "))
    weekdays_str = (task[:weekday] == "*") ? ("every day of the week") : (task[:weekday].split(",").map(&:to_i).map {|w| weekdays[w] }.join_human(", "))

    task[:schedule] = "#{minutes_str} of #{hours_str} of #{days_str} of #{months_str} on #{weekdays_str}."
    return task
  end
end

class Dir
  def self.mkdir_if_absent(dir)
    Dir.mkdir(dir) unless File.exists?(dir) and File.directory?(dir)
  end
end

class CronEdit::Crontab
  def list_maintainer
    self.list.delete_if { |k,v| not /^maintainer/ =~ k }
  end
end

module Merb::Maintainer::Utils
  include Merb::Maintainer::Constants

  # utility functions related to logging
  module Log
    def log(data)
      h = DM_REPO.scope {
        Maintainer::HistoryItem.create(
          :user_name   => session.user.login,
          :ip          => data[:ip],
          :time        => Time.now,
          :action      => data[:action],
          :data        => data[:name]
        )
      }
    end
  end

  # utility functions related to the database (backup, upgrade, etc)
  module Database
    def database_backup
      Dir.mkdir_if_absent(DB_FOLDER)
      Dir.mkdir_if_absent(DUMP_FOLDER)

      username = DB_CONFIG[Merb.env]["username"]
      password = DB_CONFIG[Merb.env]["password"]
      database = DB_CONFIG[Merb.env]["database"]
      today = `date +%H:%M:%S.%Y-%m-%d`.chomp
      snapshot_path = File.join(DUMP_FOLDER,"#{database.sub(/^mostfit_/,'')}.#{today}.sql")

      if password.nil? or password.blank?
        `mysqldump -u #{username} #{database} > #{snapshot_path}; bzip2 #{snapshot_path}` unless File.exists?(snapshot_path+".bz2")
      else
        `mysqldump -u #{username} -p#{password} #{database} > #{snapshot_path}; bzip2 #{snapshot_path}` unless File.exists?(snapshot_path+".bz2")
      end

      return snapshot_path
    end

    def database_upgrade
      `rake db:autoupgrade > #{slice_path("log/db_upgrade.log")}`
    end
  end

  # utility functions related to the currently running Merb instance
  module Instance
    def instance_start
      # start instance (stopped by instance_take_offline)
      `touch tmp/start.txt`
    end
    
    def instance_take_offline
      # take the site offline for maintenance
      `touch tmp/stop.txt`
    end

    def instance_restart
      # restart instance
      `touch tmp/restart.txt`
    end
  end

  # returns a slice-level path for the given location
  def slice_path(*locations)
    File.join(Merb.root, SLICE_PATH, locations)
  end

  # returns an app-level path for the given location
  def app_path(*locations)
    File.join(Merb.root, locations)
  end
end
