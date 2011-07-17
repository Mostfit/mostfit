class ProjectedReport < Report
  attr_accessor :from_date, :to_date, :branch, :center, :branch_id, :center_id, :staff_member_id, :loan_product_id, :include_past_data
#  validates_with_method :branch_id, :branch_should_be_selected

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
    debugger
    #0              1                2              3                 4                 5,                  6                    7      
    #amount_applied,amount_santioned,outstanding(p),outstanding(i),outstanding(fee),Outstanding(total),principal(scheduled),interest(scheudled),fee(scheduled)
    branches, centers, data = {}, {}, {}
    extra =  ["lh.branch_id in (#{@branch.map{|b| b.id}.join(", ")})"]
    extra << ["lh.center_id in (#{@center.map{|b| b.id}.join(", ")})"]

    outstanding_at_from_date = LoanHistory.sum_outstanding_grouped_by(from_date - 1 , :loan, extra).group_by{|x| x.loan_id}
    
    LoanHistory.all("loan.deleted_at" => nil, :center_id => @center.map{|c| c.id}, :status => [:disbursed, :outstanding],
                    :date => from_date..to_date).aggregate(:branch_id, :date, :center_id, :loan_id, 
                                                           :scheduled_outstanding_principal.sum, :scheduled_outstanding_total.sum).group_by{|lh| 
      lh[0]
    }.map{|bid, date_rows| [bid, date_rows.group_by{|d| d[1]}]}.to_hash.each{|bid, dates|
      next unless branch = @branch.find{|b| b.id == bid}
      data[branch] ||= {}
      branches[bid] = branch
      branch_dates = dates.keys.sort
      loan_data = {}

      dates.sort_by{|date, rows| date}.each{|date, centers|
        next if centers.length == 0
        data[branch][date] = {}
        centers.each{|row|
          next unless center = @center.find{|c| c.id == row[2]}
          data[branch][date][center] ||= [0, 0, 0, 0, 0, 0, 0]
          # first row is treated specially as outstanding at this point is subtracted from already existing balance
          loan_id = row[3]
          if not data[branch][date][center] or not loan_data[loan_id]
            loan_data[loan_id] = {}
            pre_outstanding_principal = outstanding_at_from_date[loan_id] ? outstanding_at_from_date[loan_id].first.scheduled_outstanding_principal : 0
            pre_outstanding_total     = outstanding_at_from_date[loan_id] ? outstanding_at_from_date[loan_id].first.scheduled_outstanding_total : 0
            data[branch][date][center][4] += pre_outstanding_principal - row[4]
            data[branch][date][center][5] += (pre_outstanding_total - pre_outstanding_principal) - (row[5] - row[4])
            data[branch][date][center][6] += pre_outstanding_total - row[5]
          else
            last_date = loan_data[loan_id].keys.max
            next unless data[branch][date] and data[branch][date][center]
            if loan_data[loan_id] and loan_data[loan_id][last_date]
              data[branch][date][center][4] += (loan_data[loan_id][last_date][0] - row[4])
              data[branch][date][center][5] += (loan_data[loan_id][last_date][1] - loan_data[loan_id][last_date][0] - (row[5] - row[4]))
              data[branch][date][center][6] += (loan_data[loan_id][last_date][1] - row[5])
            end
          end
          loan_data[loan_id][date] = [row[4], row[5]]
        } #rows
      } #dates
    } #branch

    if @include_past_data == 1
      past_date = Date.min_date - 1
      
      #7 Overdue payments: likely to come in this week
      hash = {}
      hash[:branch_id] = @branch.map{|b| b.id}
      hash[:center_id] = @center.map{|b| b.id}
      LoanHistory.defaulted_loan_info_by(:center, Date.today - 1, hash, ["branch_id", "date", "center_id"]).each{|row|
        next unless branch = @branch.find{|b| b.id == row.branch_id}
        next unless center = @center.find{|c| c.id == row.center_id}
        
        data[branch] ||= {}
        data[branch][past_date] ||= {}
        data[branch][past_date][center] ||= [0, 0, 0, 0, 0, 0, 0]
        
        data[branch][past_date][center][4]= row.pdiff
        data[branch][past_date][center][5]= row.tdiff - row.pdiff
        data[branch][past_date][center][6]= row.tdiff
      }
    
      #1: late disbursals
      hash = {:scheduled_disbursal_date.lt => from_date, :disbursal_date => nil, :rejected_on => nil}
      hash[:loan_product_id] = loan_product_id if loan_product_id
      
      group_loans(["c.id"], ["SUM(amount_applied_for) as amount", "b.id branch_id, c.id center_id"], hash).each{|row|
        next unless branch = @branch.find{|b| b.id == row.branch_id}
        next unless center = @center.find{|c| c.id == row.center_id}
        
        data[branch] ||= {}
        data[branch][past_date] ||= {}
        data[branch][past_date][center] ||= [0, 0, 0, 0, 0, 0, 0]
        data[branch][past_date][center][0] += row.amount.to_i
      }
      
      #1: late disbursals but sanctioned
      hash = {:scheduled_disbursal_date.lt => from_date, :approved_on.not => nil, :disbursal_date => nil, :rejected_on => nil}
      hash[:loan_product_id] = loan_product_id if loan_product_id
      
      group_loans(["c.id"], ["SUM(amount_sanctioned) as amount", "b.id branch_id, c.id center_id"], hash).each{|row|
        next unless branch = @branch.find{|b| b.id == row.branch_id}
        next unless center = @center.find{|c| c.id == row.center_id}
        
        data[branch] ||= {}
        data[branch][past_date] ||= {}
        data[branch][past_date][center] ||= [0, 0, 0, 0, 0, 0, 0]
        data[branch][past_date][center][1] += row.amount.to_i
      }
    end

    #2: applications
    hash = {:scheduled_disbursal_date.gte => from_date, :scheduled_disbursal_date.lte => to_date, :disbursal_date => nil, :rejected_on => nil}
    hash[:loan_product_id] = loan_product_id if loan_product_id

    group_loans(["l.scheduled_disbursal_date", "c.id"], ["SUM(amount_applied_for) as amount", "b.id branch_id, c.id center_id"], hash).each{|row|
      next unless branch = @branch.find{|b| b.id == row.branch_id}
      next unless center = @center.find{|c| c.id == row.center_id}

      data[branch] ||= {}
      data[branch][row.scheduled_disbursal_date] ||= {}
      data[branch][row.scheduled_disbursal_date][center] ||= [0, 0, 0, 0, 0, 0, 0]
      data[branch][row.scheduled_disbursal_date][center][2] += row.amount.to_i
    }
    
    #3: appovals
    hash[:approved_on.not]=nil
    group_loans(["l.scheduled_disbursal_date", "c.id"], ["SUM(amount_sanctioned) as amount", "b.id branch_id, c.id center_id"], hash).each{|row|
      next unless branch = @branch.find{|b| b.id == row.branch_id}
      next unless center = @center.find{|c| c.id == row.center_id}

      data[branch] ||= {}
      data[branch][row.scheduled_disbursal_date] ||= {}
      data[branch][row.scheduled_disbursal_date][center] ||= [0, 0, 0, 0, 0, 0, 0]
      data[branch][row.scheduled_disbursal_date][center][3] += row.amount.to_i
    }

    return data
  end
end
