class DailyReport < Report
  attr_accessor :date, :loan_product_id, :branch_id, :center_id, :staff_member_id

  def initialize(params, dates, user)
    @date   =  dates[:date]||Date.today
    @name   = "Report for #{@date}"
    get_parameters(params, user)
  end
  
  def name
    "Daily Report for #{date}"
  end

  def self.name
    "Daily report"
  end
  
  def generate
    branches, centers, data, clients, loans, groups = {}, {}, {}, {}, {}, {}
    histories = LoanHistory.sum_outstanding_grouped_by(self.date, [:center, :client_group], self.loan_product_id)
    advances  = LoanHistory.sum_advance_payment(self.date, self.date, :client_group)||[]
    balances  = LoanHistory.advance_balance(self.date, :client_group)||[]
    old_balances = LoanHistory.advance_balance(self.date-1, :client_group)||[]

    center_keys  = @center.map{|c| c.id}
    @center.each{|c| centers[c.id] = c}
    ClientGroup.all(:fields => [:id, :name, :center_id]).each{|g| 
      groups[g.id] = g
    }


    @branch.each{|b|
      data[b]||= {}
      branches[b.id] = b
      b.centers.each{|c|
        next if @center and not @center.find{|x| x.id==c.id}
        data[b][c]||= {}
        c.client_groups(:fields => [:id, :name]).each{|g|
          #0              1                 2                3                  4     5   6                  7                   8               9               10
          #amount_applied,amount_sanctioned,amount_disbursed,bal_outstanding(p),bo(i),tot,principal_paidback,interest_collected, processing_fee, no_of_defaults, name
          history  = histories.find{|x| x.client_group_id==g.id and x.center_id==c.id} if histories
          advance  = advances.find{|x|  x.client_group_id==g.id}
          balance  = balances.find{|x|  x.client_group_id==g.id}
          old_balance = old_balances.find{|x| x.client_group_id==g.id}

          if history
            data[b][c][g] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
            principal_scheduled = history.scheduled_outstanding_principal.to_i
            total_scheduled     = history.scheduled_outstanding_total.to_i

            principal_actual = history.actual_outstanding_principal.to_i
            total_actual     = history.actual_outstanding_total.to_i
          else
            next
          end

          data[b][c][g][7] += principal_actual
          data[b][c][g][9] += total_actual
          data[b][c][g][8] += total_actual - principal_actual

          data[b][c][g][10] += (principal_actual > principal_scheduled ? principal_actual-principal_scheduled : 0)
          data[b][c][g][11] += ((total_actual-principal_actual) > (total_scheduled-principal_scheduled) ? (total_actual-principal_actual - (total_scheduled-principal_scheduled)) : 0)
          data[b][c][g][12] += total_actual > total_scheduled ? total_actual - total_scheduled : 0

          advance_total = advance ? advance.advance_total : 0
          balance_total = balance ? balance.balance_total : 0
          old_balance_total = old_balance ? old_balance.balance_total : 0
        
          data[b][c][g][13]  += advance_total
          data[b][c][g][15]  += balance_total
          data[b][c][g][14]  += advance_total - balance_total + old_balance_total

        }
      }
    }
    
    hash = {:principal_paid.not => nil, :date => date, :center_id => center_keys}
    hash["loan.loan_product_id"] = loan_product_id if loan_product_id
    # principal and interest paid
    LoanHistory.all(hash).aggregate(:branch_id, :center_id, :client_group_id, :principal_paid.sum, :interest_paid.sum).each{|p|
      next unless center = centers[p[1]]
      branch = branches[p[0]]
      if data[branch][center]
        group = groups[p[2]]
        data[branch][center][group] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        data[branch][center][group][3] += p[3].round(2)
        data[branch][center][group][4] += p[4].round(2)
      end
    }

    #1: Applied on
    hash = {:status => :applied, :date => date, :center_id => center_keys}
    hash["loan.loan_product_id"] = loan_product_id if loan_product_id
    LoanHistory.all(hash).each{|l|
      branch = branches[l.branch_id]
      center = centers[l.center_id]
      group = groups[l.client_group_id]
      data[branch][center][group] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
      data[branch][center][group][0] += l.amount_applied_for||l.amount    
    }

    #2: Approved on
    hash = {:status => :approved, :date => date, :center_id => center_keys}
    hash["loan.loan_product_id"] = loan_product_id if loan_product_id
    LoanHistory.all(hash).each{|l|
      branch = branches[l.branch_id]
      center = centers[l.center_id]
      group = groups[l.client_group_id]
      data[branch][center][group] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
      data[branch][center][group][1] += l.loan.amount_sanctioned||l.loan.amount
    }

    #3: Disbursal date
    hash = {:status => :disbursed, :date => date, :center_id => center_keys}
    hash["loan.loan_product_id"] = loan_product_id if loan_product_id
    LoanHistory.all(hash).each{|l|
      branch = branches[l.branch_id]
      center = centers[l.center_id]
      group = groups[l.client_group_id]
      data[branch][center][group] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
      data[branch][center][group][3] += l.scheduled_outstanding_principal
    }
    return data
  end
end
