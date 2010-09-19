if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'production')

namespace :mostfit do
  desc "Update history of all loans"
  task :eod  do
    count = Loan.all.count
    puts count
    
    Loan.all(:disbursal_date.lte => Date.today, :fields => [:id], :limit => 100).each{|l|
      l.update_history
      puts l
    }
  end
end
