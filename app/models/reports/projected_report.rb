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
    branches, centers, clients, data = {}, {}, {}, {}
    histories = LoanHistory.sum_outstanding_by_group(self.from_date, self.to_date, self.loan_product_id)
    @branch.each{|b|
      data[b]||= {}
      branches[b.id] = b
      
      b.centers.each{|c|
        next if @center and not @center.find{|x| x.id==c.id}
        data[b][c]||= {}
        centers[c.id]  = c
        c.client_groups.each{|g|
          #0              1                2              3                 4                 5,                  6                    7      
          #amount_applied,amount_santioned,outstanding(p),outstanding(i),outstanding(fee),Outstanding(total),principal(scheduled),interest(scheudled),fee(scheduled)
          data[b][c][g] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
          history  = histories.find{|x| x.client_group_id==g.id and x.center_id==c.id} if histories
          if history
            principal_scheduled = history.scheduled_outstanding_principal.to_i
            total_scheduled     = history.scheduled_outstanding_total.to_i

            principal_actual = history.actual_outstanding_principal.to_i
            total_actual     = history.actual_outstanding_total.to_i            
          else
            principal_scheduled, total_scheduled, principal_actual, total_actual = 0, 0, 0, 0
          end

          data[b][c][g][2] += principal_actual - principal_scheduled > 0 ? principal_actual - principal_scheduled : 0
          int  = (total_actual - total_scheduled) - (principal_actual - principal_scheduled)
          data[b][c][g][3] += int >0 ? int : 0
          data[b][c][g][4] += 0
          data[b][c][g][5] += total_actual - total_scheduled>0 ? total_actual - total_scheduled : 0 

          data[b][c][g][6] += principal_scheduled
          data[b][c][g][7] += total_scheduled - principal_scheduled
          data[b][c][g][8] += 0
          data[b][c][g][9] += total_scheduled
        }
      }
    }

    center_ids  = centers.keys.length>0 ? centers.keys.join(',') : "NULL"
    Client.all(:center_id => centers.keys, :fields => [:id, :center_id, :client_group_id]).each{|c|
      clients[c.id] = c
    }

    #1: Applied on
    hash= {:scheduled_disbursal_date.gte => from_date, :scheduled_disbursal_date.lte => to_date, :rejected_on => nil}
    hash[:loan_product_id] = loan_product_id if loan_product_id

    Loan.all(hash).each{|l|
      next if not clients.key?(l.client_id)
      center_id = clients[l.client_id].center_id
      next if not centers.key?(center_id)
      center = centers[center_id]
      branch = branches[center.branch_id]
      data[branch][center][clients[l.client_id].client_group][0] += l.amount_applied_for||l.amount
    }
    
    hash[:approved_on.not]=nil
    Loan.all(hash).each{|l|
      next if not clients.key?(l.client_id)
      center_id = clients[l.client_id].center_id
      next if not centers.key?(center_id)
      center = centers[center_id]
      branch = branches[center.branch_id]
      data[branch][center][clients[l.client_id].client_group][1] += l.amount_sanctioned||l.amount
    }
    return data
  end
end
