OBJECTS_UNDER_OBSERVATION = [Client, Loan, LoanProduct]

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
      if args[:begin_date].nil?
        puts
        puts "ERROR: Please give atleast one date as an argument" 
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
        clients = Client.all(:created_at.gte => begin_date, :created_at.lte => end_date)
        loan_products = LoanProduct.all(:created_at.gte => begin_date, :created_at.lte => end_date)
        loans = Loan.all(:created_at.gte => begin_date, :created_at.lte => end_date)
        everyone = clients + loan_products + loans
        everyone_sorted = everyone.sort_by{|x| x.created_at}
        everyone.each do |obj|
          obj_class = nil
          OBJECTS_UNDER_OBSERVATION.each{|x|
            obj_class =  x.to_s.downcase.to_sym if obj.is_a?(x)
          }
          log = ModelEventLog.create(
                                     :parent_org_guid => obj.parent_org_guid,
                                     :parent_domain_guid => obj.parent_domain_guid,
                                     :event_change => :create, 
                                     :event_changed_at => DateTime.now,
                                     :event_on_type => obj_class,     
                                     :event_on_id => obj.id,    
                                     :event_on_name => ((obj.respond_to?(:name)) ? obj.name : nil),
                                     :event_accounting_action => :allow, 
                                     :event_accounting_action_effective_date => nil
                                     )
        end
        puts
        puts "The event logs have been repopulated"
      else
        puts "ERROR: The begin date #{begin_date} is greater than the end date #{end_date}." 
      end
    end
  end
end
