if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'production')

namespace :mostfit do
  desc "Update history of all loans"
  task :eod  do
    loan_ids = Payment.all(:received_on => Date.today - 1).map{|l| l.loan_id}.compact.uniq
    puts loan_ids.count
    
    loan_ids.each{|lid|
      puts lid
      Loan.get(lid).update_history
    }
  end
end
