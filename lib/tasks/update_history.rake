if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'production')

namespace :mostfit do
  desc "Update history of all loans"
  task :eod  do
    loan_ids = Payment.all(:created_at.gte => Date.today, :type => :principal).aggregate(:loan_id).compact.uniq
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
    problems.each{|lid|
      Loan.get(lid).update_history
      puts lid
    }
    # update loans where OS + paid != disbursed
    problems = []
    data = LoanHistory.sum_outstanding_grouped_by(Date.today, :loan).map{|lh| [lh.loan_id, lh.actual_outstanding_principal.to_i]}.to_hash; puts
    disbursals = Loan.all(:disbursal_date.lte => Date.today, :rejected_on => nil).aggregate(:id, :amount.sum).to_hash
    payments   = Payment.all(:type => :principal).aggregate(:loan_id, :amount.sum).to_hash
    problems = data.map{|lid, os| 
      [lid, disbursals[lid] - os - (payments[lid]||0)]
    }.find_all{|k,v| v!=0}.to_hash
    problems.keys.each{|lid| 
      puts lid
      Loan.get(lid).update_history
    }
    
    centers = Center.all.map{|c|
      [c.id, c.branch_id]
    }.to_hash
    problems = LoanHistory.all(:current => 1, :status => :outstanding, :date.lt => Date.today).find_all{|lh|
      centers[lh.center_id]!=lh.branch_id
    }.map{|lh| lh.loan_id}
    Loan.all(:id => data).each{|l| 
      puts l.id
      l.update_history
    }
  end
end
