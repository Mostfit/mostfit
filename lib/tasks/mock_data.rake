require "rubygems"

# Add the local gems dir if found within the app root; any dependencies loaded
# hereafter will try to load from the local gems before loading system gems.
if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end

require "merb-core"

# this loads all plugins required in your init file so don't add them
# here again, Merb will do it for you
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'production')

namespace :mostfit do
  namespace :data do
    desc "Generate all payments for all loans without payments as if everyone paid dilligently (does not write any history)"
    task :all_payments do
      puts "starting"
      t0 = Time.now
      Merb.logger.info! "Start mock:all_payments rake task at #{t0}"
      busy_user = User.get(1)
      count = 0
      if Payment.all.empty?
        loan_ids = repository.adapter.query("SELECT id from loans WHERE deleted_at IS NULL")
      else
        loan_ids = repository.adapter.query("SELECT id from loans WHERE id > (select max(loan_id) from payments) AND deleted_at IS NULL")
      end
      puts "1: #{Time.now - t0}"
      loan_ids.each do |loan_id|
        sql = " INSERT INTO `payments` (`received_by_staff_id`, `amount`, `type`, `created_by_user_id`, `loan_id`, `received_on`, `client_id`) VALUES ";
        _t0 = Time.now
        loan = Loan.get(loan_id)
        staff_member = loan.client.center.manager
        p "Doing loan No. #{loan.id}...."
        loan.history_disabled = true  # do not update the hisotry for every payment
        dates      = loan.installment_dates.reject { |x| x > Date.today or x < loan.disbursal_date }
        values = []
        dates.each do |date|
          prin = loan.scheduled_principal_for_installment(loan.installment_for_date(date))
          int = loan.scheduled_interest_for_installment(loan.installment_for_date(date))
          values << "(#{staff_member.id}, #{prin}, 1, 1, #{loan.id}, '#{date}', #{loan.client.id})"
          values << "(#{staff_member.id}, #{int}, 2, 1, #{loan.id}, '#{date}', #{loan.client.id})"
          count += 1
        end
        puts "done constructing sql in #{Time.now - _t0}"
        if not values.empty?
          sql += values.join(",")
          repository.adapter.execute(sql)
          puts "done executing sql in #{Time.now - _t0}"
          puts "---------------------"
        end
        p "done in #{Time.now - _t0} secs. Total time: #{Time.now - t0} secs"
      end
      #    end
      t1 = Time.now
      secs = (t1 - t0).round
      Merb.logger.info! "Finished mock:all_payments rake task in #{secs} secs for #{Loan.all.size} loans creating #{count} payments, at #{t1}"
    end

    desc "Clear loan_history table"
    task :clear_history do
      puts "truncating loan_history table"
      repository.adapter.execute("truncate table loan_history;")
    end

    desc "Update missing loan_histories"
    task :create_history do
      t0 = Time.now
      puts "finding unhistorified loans"
      lids = Loan.all.aggregate(:id)
      hids = LoanHistory.all.aggregate(:loan_id)
      loan_ids = lids - hids
      puts "got loan ids"
      t0 = Time.now
      co = loan_ids.count
      loan_ids.each_with_index do |loan_id, idx|
        begin
          loan = Loan.get(loan_id)
          next unless loan
          loan.update_history
          print "."
        rescue
          print "!"
          puts loan_id
        end
        pdone = (idx + 1)/co.to_f
        elapsed = (Time.now - t0).round
        avg_s_per_loan = (elapsed.to_f/(idx + 1)).round(2)
        status_line = "\n#{idx}/#{co} or #{(pdone*100).round(2)}% in #{elapsed} secs ETA #{(avg_s_per_loan * (co - idx) / 60).round(2)} mins: Avg #{avg_s_per_loan} s/loan\n"
        print status_line if idx%50 == 0
      end
      t1 = Time.now
      secs = (t1 - t0).round
      Merb.logger.info! "Finished mock:history rake task in #{secs} secs for #{Loan.all.size} loans with #{Payment.all.size} payments, at #{t1}"
     # log.close
    end

  end
end




