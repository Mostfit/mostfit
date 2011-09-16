require "rubygems"

# Add the local gems dir if found within the app root; any dependencies loaded
# hereafter will try to load from the local gems before loading system gems.
if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end

require "merb-core"

# this loads all plugins required in your init file so don't add them
# here again, Merb will do it for you
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')

namespace :mostfit do
  namespace :regenerate do
    desc "This rake task re-generates event logs for the given date range"
    task :event_logs, :begin_date, :end_date do |t, args|
      t1 = Time.now
      if args[:begin_date].nil?
        puts
        puts "USAGE: rake mostfit:regenerate:event_logs[<from_date>,<to_date>]"
        puts
        puts "NOTE: Make sure there are no spaces after and before the comma separating the two arguments." 
        puts "      The from_date has to be supplied. If the to_date is not supplied it is assumed to be today."
        puts "      The format for the date is DD-MM-YYYY. The date has to be enclosed in single quotes. For 6th August 2011 it shall be '06-08-2011'."
        puts
        puts "EXAMPLE: rake mostfit:regenerate:event_logs['06-07-2011']"
        puts "         rake mostfit:regenerate:event_logs['06-07-2011','13-07-2011']"
        flag = 0
       else
        flag = 1
        begin_date = Date.strptime(args[:begin_date], "%d-%m-%Y")
      end

      if args[:end_date].nil?
        end_date = Date.today
      else
        end_date = Date.strptime(args[:end_date], "%d-%m-%Y")
      end
      
      if begin_date.nil? or end_date.nil?
        # Dont display this ERROR message if you have already displayed the USAGE message
        if flag == 1
          puts 
          puts "ERROR: Please give the arguments in the proper format. For 6th August 2011 it shall be '06-08-2011'"
        end
      elsif begin_date <= end_date
        everyone = []
        ModelEventLog::MODELS_UNDER_OBSERVATION.each{|x|
          everyone += x.all(:fields => [:id, :created_at, :parent_org_guid, :parent_domain_guid], :created_at.gte => begin_date, :created_at.lte => end_date)
        }
        everyone.each do |obj|
          log = ModelEventLog.new
          log.obj2model_event_log(obj)
          log.event_change = :create
          log.event_changed_at = obj.created_at
          log.event_accounting_action = :create
          if log.parent_org_guid == nil 
            org = Organization.get_organization(obj.created_at)
            log.parent_org_guid = org.org_guid
          end
          log.save 
        end
        t2 = Time.now
        puts
        puts "The event logs have been repopulated"
        puts "Time taken: #{t2-t1} seconds"
      else
        puts "ERROR: The begin date #{begin_date} is greater than the end date #{end_date}." 
      end
    end
  end
end
