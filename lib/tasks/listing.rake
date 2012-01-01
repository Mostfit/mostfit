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

    desc "List the disbursal dates of all the loans"
    task :disbursal_dates do
      @loans = Loan.all.aggregate(:c_branch_id, :c_center_id, :client_id, :id, :disbursal_date)
      f = File.open("tmp/disbursal_dates_#{DateTime.now.to_s}.csv", "w")
      f.puts("\"Branch Id\", \"Branch Name\", \"Center Id\", \"Center Name\", \"Client Id\", \"Client Name\", \"Loan Id\", \"Disbursal Date\"")
      # @loans is an array of arrays which contains branch_id, center_id, client_id, loan_id and disbursal_dates
      # in the sequence 0, 1, 2, 3, 4 respectively.
      @loans.each{|l|
        f.puts("#{l[0]}, \"#{Branch.get(l[0]).name}\", #{l[1]}, \"#{Center.get(l[1]).name}\", #{l[2]}, \"#{Client.get(l[2]).name}\", #{l[3]}, #{l[4]}")
      }
      f.close
    end
  end
end
