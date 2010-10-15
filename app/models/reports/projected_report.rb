class ProjectedReport < Report
  attr_accessor :from_date, :to_date, :branch, :center, :branch_id, :center_id, :staff_member_id, :loan_product_id

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today + 1
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today + 7
    @name   = "Projected cash flow from #{@from_date} to #{@to_date}"
    get_parameters(params, user)
 end
  
  def name
    "Projected cash flow from #{@from_date} to #{@to_date}"
  end

  def self.name
    "Cash projection report"
  end
  
  def generate
    branches, centers, data = {}, {}, {}
    extra =  ["lh.branch_id in (#{@branch.map{|b| b.id}.join(", ")})"]
    extra << ["lh.center_id in (#{@center.map{|b| b.id}.join(", ")})"]
    repository.adapter.query(%Q{SELECT branch_id, date, center_id, SUM(principal_due) principal, SUM(interest_due) interest, 
                                       scheduled_outstanding_principal, scheduled_outstanding_total,
                                       actual_outstanding_principal, actual_outstanding_total
                                FROM loan_history 
                                WHERE date <= '#{self.to_date.strftime('%Y-%m-%d')}' AND date >= '#{self.from_date.strftime('%Y-%m-%d')}'
                                GROUP BY branch_id, date, center_id}).group_by{|lh| 
      lh.branch_id
    }.map{|bid, dates| [bid, dates.group_by{|d| d.date}]}.to_hash.each{|bid, dates|
      branch = Branch.get(bid)
      data[branch] ||= {}
      branches[bid] = branch
      
      dates.each{|date, rows|
        next if rows.length == 0
        data[branch][date] = {}
        rows.each{|row|
          center = @center.find{|c| c.id == row.center_id}
          data[branch][date][center] = [0, 0, 0, 0, 0, 0, 0, 0]
          #0              1                2              3                 4                 5,                  6                    7      
          #amount_applied,amount_santioned,outstanding(p),outstanding(i),outstanding(fee),Outstanding(total),principal(scheduled),interest(scheudled),fee(scheduled)
          principal_scheduled = row.scheduled_outstanding_principal.to_i
          total_scheduled     = row.scheduled_outstanding_total.to_i
          
          principal_actual = row.actual_outstanding_principal.to_i
          total_actual     = row.actual_outstanding_total.to_i

          data[branch][date][center][3] += row.principal
          data[branch][date][center][4] += row.interest
          data[branch][date][center][5] += row.principal + row.interest          
        }
      }
    }

    #7 Overdue payments: likly to come in this week
    hash = {}
    hash[:branch_id] = @branch.map{|b| b.id}
    hash[:center_id] = @center.map{|b| b.id}
    LoanHistory.defaulted_loan_info_by(:center, self.from_date-1, hash, ["branch_id", "date", "center_id"]).each{|row|
      next unless branch = @branch.find{|b| b.id == row.branch_id}
      next unless center = @center.find{|c| c.id == row.center_id}

      data[branch] ||= {}
      date = row.date + 7
      data[branch][date] ||= {}
      data[branch][date][center] ||= [0, 0, 0, 0, 0, 0, 0, 0]

      data[branch][date][center][6]= row.pdiff
      data[branch][date][center][7]= row.tdiff - row.pdiff
      data[branch][date][center][8]= row.tdiff
    }
    
    #1: late disbursals
    hash = {:scheduled_disbursal_date.lt => from_date, :disbursal_date => nil, :rejected_on => nil}
    hash[:loan_product_id] = loan_product_id if loan_product_id

    group_loans(["c.id"], ["SUM(amount_applied_for) as amount", "b.id branch_id, c.id center_id"], hash).each{|row|
      next unless branch = @branch.find{|b| b.id == row.branch_id}
      next unless center = @center.find{|c| c.id == row.center_id}

      data[branch] ||= {}
      data[branch][Date.min_date-1] ||= {}
      data[branch][Date.min_date-1][center] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0]
      data[branch][Date.min_date-1][center][0] += row.amount.to_i
    }

    #2: applications
    hash = {:scheduled_disbursal_date.gte => from_date, :scheduled_disbursal_date.lte => to_date, :disbursal_date => nil, :rejected_on => nil}
    hash[:loan_product_id] = loan_product_id if loan_product_id

    group_loans(["l.scheduled_disbursal_date", "c.id"], ["SUM(amount_applied_for) as amount", "b.id branch_id, c.id center_id"], hash).each{|row|
      next unless branch = @branch.find{|b| b.id == row.branch_id}
      next unless center = @center.find{|c| c.id == row.center_id}

      data[branch] ||= {}
      data[branch][row.scheduled_disbursal_date] ||= {}
      data[branch][row.scheduled_disbursal_date][center] ||= [0, 0, 0, 0, 0, 0, 0, 0]
      data[branch][row.scheduled_disbursal_date][center][1] += row.amount.to_i
    }
    
    #3: appovals
    hash[:approved_on.not]=nil
    group_loans(["l.scheduled_disbursal_date", "c.id"], ["SUM(amount_applied_for) as amount", "b.id branch_id, c.id center_id"], hash).each{|row|
      next unless branch = @branch.find{|b| b.id == row.branch_id}
      next unless center = @center.find{|c| c.id == row.center_id}

      data[branch] ||= {}
      data[branch][row.scheduled_disbursal_date] ||= {}
      data[branch][row.scheduled_disbursal_date][center] ||= [0, 0, 0, 0, 0, 0, 0, 0]

      data[branch][row.scheduled_disbursal_date][center][2] += row.amount.to_i
    }

    return data
  end
end
