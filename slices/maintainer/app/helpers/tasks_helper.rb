module Merb
  module Maintainer
    module TasksHelper

      require 'slices/maintainer/lib/utils'
      MONTHS = %w(January February March April May June July August September October November December)
      WEEKDAYS = %w(Sunday Monday Tuesday Wednesday Thursday Friday Saturday)

      def get_mostfit_rake_tasks
        rake_tasks = {}
        `rake -T mostfit`.split("\n").find_all { |t| /^rake mostfit/ =~ t }.each do |rake_task|
          rake_task_parts = rake_task.split("# ").map(&:strip)
          rake_tasks[rake_task_parts[0]] = rake_task_parts[1]
        end
        rake_tasks
      end

      def schedule_to_s(task)
        minutes_str = (task[:minute] == "*") ? ("Every minute") : (task[:minute].split(",").map(&:to_i).map(&:ordinalize).join(", ")+" minute")
        hours_str = (task[:hour] == "*") ? ("every hour") : (task[:hour].split(",").map(&:to_i).map(&:ordinalize).join(", ")+" hour")
        days_str = (task[:day] == "*") ? ("every day") : (task[:day].split(",").map(&:to_i).map(&:ordinalize).join(", ")+" day")
        months_str = (task[:month] == "*") ? ("every month") : (task[:month].split(",").map(&:to_i).map {|m| MONTHS[m-1] }.join(", "))
        weekdays_str = (task[:weekday] == "*") ? ("every day of the week") : (task[:weekday].split(",").map(&:to_i).map {|w| WEEKDAYS[w] }.join(", "))
        "#{minutes_str} of #{hours_str} of #{days_str} of #{months_str} on #{weekdays_str}."
      end

    end
  end
end
