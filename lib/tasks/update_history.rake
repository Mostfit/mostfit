if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'production')

namespace :mostfit do
  desc "Update history of all loans"
  task :eod  do
    loan_ids = Payment.all(:created_at.gte => Date.today - 1).map{|l| l.loan_id}.compact.uniq
    puts loan_ids.count
    
    loan_ids.each{|lid|
      puts lid
      Loan.get(lid).update_history
    }

    data1 = repository.adapter.query("select loan_id, max(created_at) as date from loan_history lh where 1 group by lh.loan_id").map{|x| 
      [x.loan_id, x.date]
    }.to_hash
    data2 = repository.adapter.query("select p.loan_id, max(p.created_at) as date from payments p where deleted_at is NULL group by p.loan_id").map{|x| 
      [x.loan_id, x.date]
    }.to_hash
    problems = []
    data1.each{|lid, date| problems << lid if data2[lid] and (data2[lid] - date ) >0}
    problems.eahc{|lid|
      Loan.get(lid).update_history
      puts lid
    }
  end
end
