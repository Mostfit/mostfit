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
  namespace :conversion do
    desc "This rake task adds some cached values to loans"
    task :update_loan_cache do
      puts "marking centers..."
      repository.adapter.execute(%Q{
          UPDATE loans 
          SET c_center_id = (SELECT cn.id from centers cn, clients cs
             WHERE loans.client_id = cs.id AND cs.center_id = cn.id)})
      puts "marking branches..."
      repository.adapter.execute(%Q{
          UPDATE loans 
          SET c_branch_id = 
             (SELECT b.id from centers cn, clients cs, branches b
             WHERE loans.client_id = cs.id AND cs.center_id = cn.id AND cn.branch_id = b.id)})
      # repository.adapter.execute(%Q{
      #    UPDATE loans SET c_actual_first_payment_date = 
      #    (SELECT fp_date FROM 
      #        (SELECT loan_id, MIN(received_on) AS fp_date 
      #         FROM payments 
      #         WHERE type = 1 
      #         GROUP BY loan_id) AS fp_dates 
      #     WHERE fp_dates.loan_id = loans.id)})
      # puts "adding scheduled_maturity_date..."
      # repository.adapter.execute("update loans set c_scheduled_maturity_date = (SELECT max(date) from loan_history where loan_id = loans.id)")
      # puts "marking last_payment_received_on"
      # repository.adapter.execute(%Q{
      #    UPDATE loans SET c_last_payment_received_on = 
      #    (SELECT fp_date FROM 
      #        (SELECT loan_id, MAX(received_on) AS fp_date 
      #         FROM payments 
      #         WHERE type = 1 
      #         GROUP BY loan_id) AS fp_dates 
      #     WHERE fp_dates.loan_id = loans.id)})
      # puts "updating last status"
      # repository.adapter.execute(%Q{
      #   UPDATE loans l SET c_last_status = (SELECT status FROM loan_history lh WHERE lh.loan_id = l.id and current = 1)})
      # puts "updating principal received"
      # repository.adapter.execute(%Q{
      #   UPDATE loans SET c_principal_received = (SELECT SUM(amount) FROM payments WHERE loan_id = loans.id and type = 1 and deleted_at is null)})
      # puts "updating interest received"
      # repository.adapter.execute(%Q{
      #   UPDATE loans SET c_interest_received = (SELECT SUM(amount) FROM payments WHERE loan_id = loans.id and type = 2 and deleted_at is null)})
      # puts "updating maturiy date"
      # repository.adapter.execute(%Q{
      #    update loans l set c_maturity_date = (select min(date) from loan_history lh where loan_id = l.id and status > 6)})
      puts "updating client_groups"
      repository.adapter.execute(%Q{
          UPDATE loans 
          SET c_client_group_id =
          (SELECT c.client_group_id from clients c 
             WHERE loans.client_id = c.id)})
      
    end
  end
end
