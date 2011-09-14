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
    desc "This rake task re-generates transaction logs for the given date range"
    task :transaction_logs, :begin_date, :end_date do |t, args|
      t1 = Time.now
      if args[:begin_date].nil?
        puts
        puts "USAGE: rake mostfit:regenerate:transaction_logs[<from_date>,<to_date>]"
        puts
        puts "NOTE: Make sure there are no spaces after and before the comma separating the two arguments." 
        puts "      The from_date has to be supplied. If the to_date is not supplied it is assumed to be today."
        puts "      The format for the date is DD-MM-YYYY. The date has to be enclosed in single quotes. For 6th August 2011 it shall be '06-08-2011'."
        puts
        puts "EXAMPLE: rake mostfit:regenerate:transaction_logs['06-07-2011']"
        puts "         rake mostfit:regenerate:transaction_logs['06-07-2011','13-07-2011']"
        flag = 0
      else
        flag =1
        begin_date = Date.strptime(args[:begin_date], "%d-%m-%Y")
      end

      if args[:end_date].nil?
        end_date = Date.today
      else
        end_date = Date.strptime(args[:end_date], "%d-%m-%Y")
      end
      
      if begin_date.nil? or end_date.nil?
        # Dont display this ERROR message if you have already displayed the USAGE message
        if flag ==1
          puts 
          puts "ERROR: Please give the arguments in the proper format. For 6th August 2011 it shall be '06-08-2011'"
        end
      elsif begin_date <= end_date
        deleted_payments = Payment.with_deleted{ Payment.all(:received_on.gte => begin_date, :received_on.lte => end_date, :deleted_at.not => nil) }
        payments = Payment.all(:received_on.gte => begin_date, :received_on.lte => end_date)
        all_payments = deleted_payments + payments
        payments_all = all_payments.sort_by{|x| x.created_at}
        payments_all.each do |payment|
          transaction_log = TransactionLog.new
          transaction_log.payment2transaction_log(payment)
          transaction_log.update_type = :create
          if transaction_log.parent_org_guid == nil 
            org = Organization.get_organization(payment.created_at)
            transaction_log.parent_org_guid = org.org_guid 
          end
          transaction_log.save
          unless payment.deleted_at.nil?
            transaction_log = TransactionLog.new
            transaction_log.payment2transaction_log(payment)
            transaction_log.update_type = :delete 
            if transaction_log.parent_org_guid == nil 
              org = Organization.get_organization(payment.deleted_at)
              transaction_log.parent_org_guid = org.org_guid
            end
            transaction_log.save
          end
        end
        t2 =  Time.now
        puts
        puts "The transaction logs have been repopulated"
        puts "Time taken: #{t2-t1} seconds"
      else
        puts "ERROR: The begin date #{begin_date} is greater than the end date #{end_date}." 
      end
    end
  end
end
