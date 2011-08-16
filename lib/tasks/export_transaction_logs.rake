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
    desc "This rake task exports transaction logs"
    task :transaction_logs, :begin_date, :end_date do |t, args|
      debugger
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
        puts "ERROR: Please give the arguments in the proper format. For 6th August 2011 it shall be '06-08-2011' "
      elsif begin_date <= end_date 
        org_guid = Organization.get_organization(end_date)
        begin_date_time = DateTime.new(begin_date.year, begin_date.month, begin_date.day)
        end_date_time = DateTime.new(end_date.year, end_date.month, end_date.day, 23, 59, 59)
        folder = File.join(Merb.root, "doc", "transaction_event_logs")
        FileUtils.mkdir_p(folder)
        transaction_logs = TransactionLog.all(:effective_date.gte => begin_date, :effective_date.lte => end_date)
        if transaction_logs.empty?
          puts
          puts "ERROR: The transaction logs are empty"
        else
          filename = File.join(folder, "transaction_log.#{org_guid}.from.#{begin_date.strftime("%d-%m-%Y")}.to.#{end_date.strftime("%d-%m-%Y")}.xml")
          f = File.open(filename,"w")
          x = Builder::XmlMarkup.new(:target => f,:indent => 1)
          x.xml{
            x.transaction_logs{
              transaction_logs.each do |transaction_log|
                x.transaction_log{
                  x.txn_log_GUID transaction_log.txn_log_guid
                  x.txn_log_guid transaction_log.txn_log_guid      
                  x.txn_guid transaction_log.txn_guid
                  x.update_type transaction_log.update_type.to_s
                  x.txn_type transaction_log.txn_type.to_s         
                  x.nature_of_transaction transaction_log.nature_of_transaction.to_s
                  x.sub_type_id transaction_log.sub_type_id       
                  x.sub_type_name transaction_log.sub_type_name     
                  x.amount transaction_log.amount          
                  x.currency transaction_log.currency.to_s        
                  x.effective_date transaction_log.effective_date  
                  x.record_date transaction_log.record_date     
                  x.updated_at_time transaction_log.updated_at_time 
                  x.verified_at_time transaction_log.verified_at_time 
                  x.deleted_at_time transaction_log.deleted_at_time 
                  x.paid_by_type transaction_log.paid_by_type.to_s    
                  x.paid_by_id transaction_log.paid_by_id      
                  x.paid_by_name transaction_log.paid_by_name    
                  x.received_by_type transaction_log.received_by_type.to_s
                  x.received_by_id transaction_log.received_by_id  
                  x.received_by_name transaction_log.received_by_name
                  x.transacted_at_type transaction_log.transacted_at_type.to_s  
                  x.transacted_at_id transaction_log.transacted_at_id    
                  x.transacted_at_name transaction_log.transacted_at_name
                  x.parent_org_guid transaction_log.parent_org_guid
                  x.parent_domain_guid transaction_log.parent_domain_guid
                  if transaction_log.extended_info_items
                    x.extended_info_items{
                      transaction_log.extended_info_items.each do |e|
                        x.extended_info_item{
                          x.item_type e.item_type
                          x.item_id e.item_id
                          x.item_value e.item_value
                          x.parent_guid e.parent_guid
                        }
                      end
                    }
                  end
                }
              end
            }
          }
          f.close
          puts
          puts "The xml files generated are saved in the folder #{folder}"
        end
      end
    end
  end
end
