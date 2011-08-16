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
        deleted_payments = Payment.with_deleted{ Payment.all(:received_on.gte => begin_date, :received_on.lte => end_date, :deleted_at.not => nil) }
        payments = Payment.all(:received_on.gte => begin_date, :received_on.lte => end_date)
        all_payments = deleted_payments + payments
        payments_all = all_payments.sort_by{|x| x.created_at}
        payments_all.each do |payment|
          client_name = payment.client ? payment.client.name : nil
          center = payment.client && payment.client.center ? payment.client.center : nil
          center_id = center ? center.id : nil
          center_name = center ? center.name : nil
          
          staff_member = payment.received_by_staff_id ? StaffMember.get(payment.received_by_staff_id) : nil
          staff_member_name = staff_member ? staff_member.name : nil
          fee_name = payment.fee ? payment.fee.name : nil
          
          extended_info = payment.extended_info
          transaction = TransactionLog.create(
                                              :txn_guid => payment.guid,
                                              :parent_org_guid => payment.parent_org_guid,
                                              :parent_domain_guid => payment.parent_domain_guid,
                                              :update_type => :create,
                                              :txn_type => :receipt,
                                              :nature_of_transaction => "#{payment.type}_received".to_sym,
                                              :sub_type_id => payment.fee_id,
                                              :sub_type_name => fee_name,
                                              :amount => payment.amount,
                                              :currency => :INR,
                                              :effective_date => payment.received_on,
                                              :record_date => payment.created_at,
                                              :updated_at_time => nil,
                                              :verified_at_time => nil,
                                              :deleted_at_time => nil,
                                              :paid_by_type => :client,
                                              :paid_by_id => payment.client_id,
                                              :paid_by_name => client_name,
                                              :received_by_type => :staff_member,
                                              :received_by_id => payment.received_by_staff_id,
                                              :received_by_name => staff_member_name,
                                              :transacted_at_type => :center,
                                              :transacted_at_id => center_id,
                                              :transacted_at_name => center_name,
                                              :extended_info_items => extended_info  
                                              )
          unless payment.deleted_at.nil?
             transaction = TransactionLog.create(
                                                 :txn_guid => payment.guid,
                                                 :parent_org_guid => payment.parent_org_guid,
                                                 :parent_domain_guid => payment.parent_domain_guid,
                                                 :update_type => :delete,
                                                 :txn_type => :receipt,
                                                 :nature_of_transaction => "#{payment.type}_received".to_sym,
                                                 :sub_type_id => payment.fee_id,
                                                 :sub_type_name => fee_name,
                                                 :amount => payment.amount,
                                                 :currency => :INR,
                                                 :effective_date => payment.received_on,
                                                 :record_date => payment.created_at,
                                                 :updated_at_time => nil,
                                                 :verified_at_time => nil,
                                                 :deleted_at_time => payment.deleted_at,
                                                 :paid_by_type => :client,
                                                 :paid_by_id => payment.client_id,
                                                 :paid_by_name => client_name,
                                                 :received_by_type => :staff_member,
                                                 :received_by_id => payment.received_by_staff_id,
                                                 :received_by_name => staff_member_name,
                                                 :transacted_at_type => :center,
                                                 :transacted_at_id => center_id,
                                                 :transacted_at_name => center_name,
                                                 :extended_info_items => extended_info  
                                                 )
          end
        end
        puts
        puts "The transaction logs have been repopulated"
      else
        puts "ERROR: The begin date #{begin_date} is greater than the end date #{end_date}." 
      end
    end
  end
end
