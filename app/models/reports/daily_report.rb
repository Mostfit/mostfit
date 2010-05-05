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
    branches, centers, groups = {}, {}, {}
    histories = LoanHistory.sum_outstanding_by_group(self.date-7, self.date, self.loan_product_id)
    @branch.each{|b|
      groups[b.id]||= {}
      branches[b.id] = b
      b.centers.each{|c|
        next if @center and not @center.find{|x| x.id==c.id}
        groups[b.id][c.id]||= {}
        centers[c.id]  = c
        c.client_groups.each{|g|
          #0              1                 2                3                  4     5   6                  7                   8               9               10
          #amount_applied,amount_sanctioned,amount_disbursed,bal_outstanding(p),bo(i),tot,principal_paidback,interest_collected, processing_fee, no_of_defaults, name
          groups[b.id][c.id][g.id] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, g.name]
          history  = histories.find{|x| x.client_group_id==g.id and x.center_id==c.id} if histories
          if history
            principal_scheduled = history.scheduled_outstanding_principal.to_i
            total_scheduled     = history.scheduled_outstanding_total.to_i

            principal_actual = history.actual_outstanding_principal.to_i
            total_actual     = history.actual_outstanding_total.to_i
            
            principal_advance = history.advance_principal.to_i
            total_advance     = history.advance_total.to_i
          else
            principal_scheduled, total_scheduled, principal_actual, total_actual, principal_advance, total_advance = 0, 0, 0, 0, 0, 0
          end

          groups[b.id][c.id][g.id][7] += principal_actual
          groups[b.id][c.id][g.id][9] += total_actual
          groups[b.id][c.id][g.id][8] += total_actual - principal_actual

          groups[b.id][c.id][g.id][10] += (principal_actual > principal_scheduled ? principal_actual-principal_scheduled : 0)
          groups[b.id][c.id][g.id][11] += ((total_actual-principal_actual) > (total_scheduled-principal_scheduled) ? (total_actual-principal_actual - (total_scheduled-principal_scheduled)) : 0)
          groups[b.id][c.id][g.id][12] += total_actual > total_scheduled ? total_actual - total_scheduled : 0

          groups[b.id][c.id][g.id][13]  += principal_advance
          groups[b.id][c.id][g.id][15] += total_advance
          groups[b.id][c.id][g.id][14] += (total_advance - principal_advance)
        }
      }
    }
    
    Payment.all(:received_on => date).each{|p|
      client    = p.loan_id ? p.loan.client : p.client
      center_id = client.center_id
      next if not centers.key?(center_id)
      next if loan_product_id and p.loan.loan_product_id!=loan_product_id
      branch_id = centers[center_id].branch_id
      if groups[branch_id][center_id][client.client_group_id]
        groups[branch_id][center_id][0] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, "No group"] if not client.client_group_id and not groups[branch_id][center_id][0]
        groups[branch_id][center_id][client.client_group_id][3] += p.amount if p.type==:principal
        groups[branch_id][center_id][client.client_group_id][4] += p.amount if p.type==:interest
        groups[branch_id][center_id][client.client_group_id][5] += p.amount if p.type==:fees
      end
    }
    #1: Applied on
    hash = {:applied_on => date}
    hash[:loan_product_id] = loan_product_id if loan_product_id
    Loan.all(hash).each{|l|
      client    = l.client
      center_id = client.center_id
      next if not centers.key?(center_id)
      branch_id = centers[center_id].branch_id
      groups[branch_id][center_id][0] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, "No group"] if not client.client_group_id and not groups[branch_id][center_id][0]
      groups[branch_id][center_id][l.client.client_group_id ? l.client.client_group_id : 0][0] += l.amount
    }

    #2: Approved on
    hash = {:approved_on => date}
    hash[:loan_product_id] = loan_product_id if loan_product_id
    Loan.all(hash).each{|l|
      client    = l.client
      center_id = client.center_id
      next if not centers.key?(center_id)
      branch_id = centers[center_id].branch_id
      groups[branch_id][center_id][0] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, "No group"] if not client.client_group_id and not groups[branch_id][center_id][0]
      groups[branch_id][center_id][l.client.client_group_id ? l.client.client_group_id : 0][1] += l.amount
    }

    #3: Disbursal date
    hash = {:disbursal_date => date}
    hash[:loan_product_id] = loan_product_id if loan_product_id
    Loan.all(hash).each{|l|
      client    = l.client
      center_id = client.center_id
      next if not centers.key?(center_id)
      branch_id = centers[center_id].branch_id
      groups[branch_id][center_id][0] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, "No group"] if not client.client_group_id and not groups[branch_id][center_id][0]
      groups[branch_id][center_id][l.client.client_group_id ? l.client.client_group_id : 0][2] += l.amount
    }
    return [groups, centers, branches]
  end
end
