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
  namespace :export do
    desc "This rake task exports event logs"
    task :event_logs, :begin_date, :end_date do |t, args|
      t1 =  Time.now
      if args[:begin_date].nil?
        puts
        puts "USAGE: rake mostfit:export:event_logs[<from_date>,<to_date>]"
        puts
        puts "NOTE: Make sure there are no spaces after and before the comma separating the two arguments." 
        puts "      The from_date has to be supplied. If the to_date is not supplied it is assumed to be today."
        puts "      The format for the date is DD-MM-YYYY. The date has to be enclosed in single quotes. For 6th August 2011 it shall be '06-08-2011'."
        puts
        puts "EXAMPLE: rake mostfit:export:event_logs['06-07-2011']"
        puts "         rake mostfit:export:event_logs['06-07-2011','13-07-2011']"
        flag = 0
      else
        flag = 1
        begin_date = Date.parse(args[:begin_date])
      end
      
      if args[:end_date].nil?
        end_date = Date.today
      else
        end_date = Date.parse(args[:end_date])
      end
      
      if begin_date.nil? or end_date.nil?
        # Dont display this ERROR message if you have already displayed the USAGE message
        if flag == 1
          puts
          puts "ERROR: Please give the arguments in the proper format. For 6th August 2011 it shall be '06-08-2011'"
        end
      elsif begin_date <= end_date 
        org_guid = Organization.get_organization(end_date).org_guid
        begin_date_time = DateTime.new(begin_date.year, begin_date.month, begin_date.day)
        end_date_time = DateTime.new(end_date.year, end_date.month, end_date.day, 23, 59, 59)
        folder = File.join(Merb.root, "doc", "transaction_event_logs")
        FileUtils.mkdir_p(folder)
        model_event_logs = ModelEventLog.all(:event_changed_at.gte => begin_date_time, :event_changed_at.lte => end_date_time)
        if model_event_logs.empty?
          puts
          puts "ERROR: The event logs are empty"
        else
          filename = File.join(folder, "event_log.#{org_guid}.from.#{begin_date.strftime("%d-%m-%Y")}.to.#{end_date.strftime("%d-%m-%Y")}.xml")
          f = File.open(filename,"w")
          mel = Builder::XmlMarkup.new(:target => f,:indent => 1)
          mel.xml{
            mel.event_logs{
              model_event_logs.each do |model_event_log|
                model_event_log.to_xml(mel).call
              end
            }
          }
          f.close
          t2 = Time.now
          puts
          puts "The xml files generated are saved as #{filename}"
          puts "Time taken: #{t2-t1} seconds"
        end
      else
        puts
        puts "ERROR: The begin date #{begin_date} is greater than the end date #{end_date}." 
      end
    end
  end
end
