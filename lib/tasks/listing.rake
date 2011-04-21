require "rubygems"

if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'production')

namespace :mostfit do
  namespace :listing do 
    desc "List all the overdue loans"
    task :overdue, :date  do |task, args|
      date = Date.parse(args[:date])
      @branches = Branch.all.aggregate(:id, :name).to_hash
      @centers  = Center.all.aggregate(:id, :name).to_hash
      f = File.open("tmp/list_overdue_#{DateTime.now.to_s}.csv", "w")
      f.puts("\"Branch\", \"Center\", \"Client Id\", \"Client Name\", \"Disbursed Amount\", \"Total Outstanding\", \"Principal Overdue\", \"Interest Overdue\", \"Total\", \"Days Overdue\"")
      LoanHistory.defaulted_loan_info_by([:branch, :center, :client], date, {}, "sum(lh.actual_outstanding_principal) os, lh.days_overdue, sum(l.amount) amount, min(lh.date) min_date").each{|lh|
        f.puts("\"#{@branches[lh.branch_id]}\", \"#{@centers[lh.center_id]}\", #{lh.client_id}, \"#{Client.get(lh.client_id).name}\", #{lh.amount.to_i}, #{lh.os.to_i}, #{lh.pdiff.to_i}, #{(lh.tdiff-lh.pdiff).to_i}, #{lh.tdiff.to_i}, #{date-lh.min_date+lh.days_overdue}")        
      }
      f.close
    end
 
    desc "List of Outstanding Loans"
    task :outstanding, :date do |tast, args|
      date = Date.parse(args[:date])
      f = File.open("tmp/outstanding_year_end_#{DateTime.now.to_s}.csv", "w")
      f.puts("\"Client Id\", \"Client Name\", \"Loan Id\", \"Amount Disbursed\", \"Amount Outstanding\", \"Next Installment Date\", \"Principal\", \"Interest\", \"Total\", \"No. Of Days\", \"Prorata Principal\", \"Prorata Interst\", \"Prorata Total\"")
      LoanHistory.sum_outstanding_grouped_by(date, [:client, :loan], {}, "l.amount amount").each{|lh|
        next_ins = LoanHistory.first(:date.gt => date, :loan_id => lh.loan_id, :order => [:date])
        prev_ins = LoanHistory.first(:date.lte => date, :loan_id => lh.loan_id, :order => [:date.desc])
        
        if next_ins
          days     = next_ins.date - prev_ins.date
          prin_due  = lh.scheduled_outstanding_principal - next_ins.scheduled_outstanding_principal
          total_due = lh.scheduled_outstanding_total - next_ins.scheduled_outstanding_total
          int_due   = total_due - prin_due
  
          prorata_prin = prin_due * (date - prev_ins.date) / days
          prorata_int  = int_due  * (date - prev_ins.date) / days
          prorata_total = prorata_prin + prorata_int
        else
          days = date - prev_ins.date
          prin_due  = lh.scheduled_outstanding_principal
          total_due = lh.scheduled_outstanding_total
          int_due   = total_due - prin_due

          prorata_prin = prin_due
          prorata_int  = int_due
          prorata_total = prorata_prin + prorata_int
        end
        
        f.puts("#{lh.client_id}, \"#{Client.get(lh.client_id).name}\", #{lh.loan_id}, #{lh.amount.to_i}, #{lh.actual_outstanding_principal.to_i}, \"#{(next_ins ? next_ins.date : 'no dues')}\", #{prin_due.to_i},  #{int_due.to_i}, #{total_due.to_i}, #{days.to_i}, #{prorata_prin.round(2)}, #{prorata_int.round(2)}, #{prorata_total.round(2)}")               
      }
      f.close
    end
  end
end
