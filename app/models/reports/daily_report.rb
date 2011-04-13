class DailyReport < Report
  attr_accessor :date, :loan_product_id, :branch_id, :staff_member_id, :center_id

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
    branches, centers, data, clients, loans = {}, {}, {}, {}, {}
    histories = (LoanHistory.sum_outstanding_grouped_by(self.date, [:center], self.loan_product_id)||{}).group_by{|x| x.center_id}
    advances  = (LoanHistory.sum_advance_payment(self.date, self.date, :center)||{}).group_by{|x| x.center_id}
    balances  = (LoanHistory.advance_balance(self.date, :center)||{}).group_by{|x| x.center_id}
    old_balances = (LoanHistory.advance_balance(self.date-1, :center)||{}).group_by{|x| x.center_id}

    @center.each{|c| centers[c.id] = c}

    @branch.each{|b|
      data[b]||= {}
      branches[b.id] = b
      b.centers.each{|c|
        next unless centers.key?(c.id)
        data[b][c] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        #0              1                 2                3                  4     5   6                  7                   8               9               10
        #amount_applied,amount_sanctioned,amount_disbursed,bal_outstanding(p),bo(i),tot,principal_paidback,interest_collected, processing_fee, no_of_defaults, name
        history  = histories[c.id][0]       if histories.key?(c.id)
        advance  = advances[c.id][0]        if advances.key?(c.id)
        balance  = balances[c.id][0]        if balances.key?(c.id)
        old_balance = old_balances[c.id][0] if old_balances.key?(c.id)
        
        if history
          principal_scheduled = history.scheduled_outstanding_principal.to_i
          total_scheduled     = history.scheduled_outstanding_total.to_i
          advance_principal   = history.advance_principal.to_i
          advance_total       = history.advance_total.to_i
          principal_actual    = history.actual_outstanding_principal.to_i
          total_actual        = history.actual_outstanding_total.to_i
        else
          next
        end
        
        #balance outstanding            
        data[b][c][7] += principal_actual
        data[b][c][9] += total_actual
        data[b][c][8] += total_actual - principal_actual
        
        #balance overdue            
        data[b][c][10] += ((principal_actual > principal_scheduled ? (principal_actual - principal_scheduled): 0) + advance_principal)
        #data[b][c][11] += ((total_actual - principal_actual) > (total_scheduled - principal_scheduled) ? (total_actual - principal_actual - (total_scheduled - principal_scheduled)) : 0)
        data[b][c][12] += ((total_actual > total_scheduled ? (total_actual - total_scheduled): 0) + advance_total)
        data[b][c][11] += (data[b][c][12] - data[b][c][10])
                    
        advance_total = advance ? advance.advance_total : 0
        balance_total = balance ? balance.balance_total : 0
        old_balance_total = old_balance ? old_balance.balance_total : 0
        
        #advance repayment            
        data[b][c][13]  += advance_total 
        data[b][c][15]  += balance_total
        data[b][c][14]  += advance_total - balance_total + old_balance_total
      }
    }
    
    hash = {:center_id => @center.map{|c| c.id}}
    hash[:loan_product_id] = self.loan_product_id if self.loan_product_id
    payment_type_colum =  {:principal => 3, :interest => 4, :fees => 5}

    # principal, interest and fees paid
    LoanHistory.sum_repayment_grouped_by(:center, date, date, hash, ["lh.branch_id"]).each{|ptype, rows|      
      rows.each{|row|
        next unless center = centers[row.center_id]
        branch = branches[row.branch_id]
        data[branch][center] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        data[branch][center][payment_type_colum[ptype]] += row.amount.round(2)
      }
    }
    
    # client fee
    repository.adapter.query(%Q{
                               SELECT c.id center_id, c.branch_id branch_id, SUM(p.amount) amount
                               FROM  payments p, clients cl, centers c
                               WHERE p.received_on = '#{date.strftime('%Y-%m-%d')}' AND p.loan_id is NULL AND p.type=3
                               AND   p.deleted_at is NULL AND p.client_id=cl.id AND cl.center_id=c.id AND cl.deleted_at is NULL AND c.id in (#{@center.map{|c| c.id}.join(', ')})
                               GROUP BY branch_id, center_id
                             }).each{|p|
      if branch = branches[p.branch_id] and center = centers[p.center_id]
        data[branch][center] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        data[branch][center][5] += p.amount.round(2)
      end
    }
 
    #1: Applied on
    LoanHistory.sum_applied_grouped_by([:branch, :center], date, date, hash).each{|l|
      next if not centers.key?(l.center_id)
      center = centers[l.center_id]
      branch = branches[l.branch_id]

      data[branch][center] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
      data[branch][center][0] += l.loan_amount
    }

    #2: Approved on
    LoanHistory.sum_approved_grouped_by([:branch, :center], date, date, hash).each{|l|
      next if not centers.key?(l.center_id)
      center = centers[l.center_id]
      branch = branches[l.branch_id]

      data[branch][center] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
      data[branch][center][1] += l.loan_amount
    }

    #3: Disbursal date
    LoanHistory.sum_disbursed_grouped_by([:branch, :center], date, date, hash).each{|l|
      next if not centers.key?(l.center_id)
      center = centers[l.center_id]
      branch = branches[l.branch_id]

      data[branch][center] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
      data[branch][center][2] += l.loan_amount
    }
    return data
  end
end
