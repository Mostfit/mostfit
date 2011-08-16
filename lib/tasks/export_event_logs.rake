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
      if args[:begin_date].nil?
        puts
        puts "ERROR: Please give atleast one date as an argument." 
      else
        begin_date = Date.strptime(args[:begin_date], "%d-%m-%Y")
      end
      
      if args[:end_date].nil?
        end_date = Date.today
      else
        end_date = Date.strptime(args[:end_date], "%d-%m-%Y")
      end
      
      if begin_date.nil? or end_date.nil?
        puts
        puts "ERROR: Please give the arguments in the proper format. For 6th August 2011 it shall be '06-08-2011'"
      elsif begin_date <= end_date 
        org_guid = Organization.get_organization(end_date)
        begin_date_time = DateTime.new(begin_date.year, begin_date.month, begin_date.day)
        end_date_time = DateTime.new(end_date.year, end_date.month, end_date.day, 23, 59, 59)
        folder = File.join(Merb.root, "doc", "transaction_event_logs")
        FileUtils.mkdir_p(folder)
        model_event_logs = ModelEventLog.all(:event_changed_at.gte => begin_date_time, :event_changed_at.lte => end_date_time)
        if model_event_logs.empty?
          puts
          puts "ERROR: The event logs are empty"
        else
          filename2 = File.join(folder, "event_log.#{org_guid}.from.#{begin_date.strftime("%d-%m-%Y")}.to.#{end_date.strftime("%d-%m-%Y")}.xml")
          f2 = File.open(filename2,"w")
          mel = Builder::XmlMarkup.new(:target => f2,:indent => 1)
          mel.xml{
            mel.event_logs{
              model_event_logs.each do |model_event_log|
                mel.event_log{
                  mel.event_log_guid model_event_log.event_guid 
                  mel.change model_event_log.event_change.to_s                           
                  mel.changed_at model_event_log.event_changed_at                       
                  mel.on_type model_event_log.event_on_type.to_s                          
                  mel.on_id model_event_log.event_on_id                            
                  mel.on_name model_event_log.event_on_name                          
                  mel.accounting_action model_event_log.event_accounting_action.to_s                
                  mel.accounting_action_effective_date model_event_log.event_accounting_action_effective_date
                  mel.parent_org_guid model_event_log.parent_org_guid
                  mel.parent_domain_guid model_event_log.parent_domain_guid   
                }
              end
            }
          }
          f2.close
          puts
          puts "The xml files generated are saved in the folder #{folder}"
        end
      else
        puts
        puts "ERROR: The begin date #{begin_date} is greater than the end date #{end_date}." 
      end
    end
  end
end
