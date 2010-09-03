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

    @branch.each{|b|
      data[b]||= {}
      branches[b.id] = b
      b.centers.each{|c|
        next if @center and not @center.find{|x| x.id==c.id}
        data[b][c]||= {}
        centers[c.id]  = c
        c.client_groups.each{|g|
          #0              1                 2                3                  4     5   6                  7                   8               9               10
          #amount_applied,amount_sanctioned,amount_disbursed,bal_outstanding(p),bo(i),tot,principal_paidback,interest_collected, processing_fee, no_of_defaults, name
          data[b][c][g] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
          history  = histories.find{|x| x.client_group_id==g.id and x.center_id==c.id} if histories
          advance  = advances.find{|x|  x.client_group_id==g.id}
          balance  = balances.find{|x|  x.client_group_id==g.id}
          old_balance = old_balances.find{|x| x.client_group_id==g.id}

          if history
            principal_scheduled = history.scheduled_outstanding_principal.to_i
            total_scheduled     = history.scheduled_outstanding_total.to_i

            principal_actual = history.actual_outstanding_principal.to_i
            total_actual     = history.actual_outstanding_total.to_i
          else
            principal_scheduled, total_scheduled, principal_actual, total_actual = 0, 0, 0, 0
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
    
    center_ids  = centers.keys.length>0 ? centers.keys.join(',') : "NULL"
    Client.all(:fields => [:id, :center_id, :client_group_id], :center_id => centers.keys).each{|c| 
      clients[c.id] = c
    }

    ClientGroup.all(:fields => [:id, :name, :center_id], :center_id => centers.keys).each{|g| 
      groups[g.id] = g
    }

    client_ids = clients.keys.length>0 ? clients.keys.join(',') : "NULL"

    #getting all the loans from the client list above. Filter also by loan product when provided
    query = "l.client_id=c.id and c.center_id in (#{center_ids})"
    query+= " and l.loan_product_id=#{self.loan_product_id}" if self.loan_product_id
    repository.adapter.query("select l.id, l.client_id, l.amount FROM loans l, clients c WHERE #{query}").each{|l|
      loans[l.id] =  l
    }

    extra_condition = ""
    froms = "payments p, clients cl, centers c"
    if self.loan_product_id
      froms+= ", loans l"
      extra_condition = " and p.loan_id=l.id and l.loan_product_id=#{self.loan_product_id}"
    end
                            
    repository.adapter.query(%Q{
                               SELECT c.branch_id branch_id, c.id center_id, cl.client_group_id client_group_id, type ptype, SUM(p.amount) amount, p.loan_id loan_id
                               FROM #{froms}
                               WHERE p.received_on = '#{date.strftime('%Y-%m-%d')}'
                               AND   p.deleted_at is NULL AND p.client_id = cl.id AND cl.center_id=c.id AND c.id in (#{center_ids}) #{extra_condition}
                               GROUP BY branch_id, center_id, client_group_id, ptype
                             }).each{|p|
      next unless center = centers[p.center_id]
      branch = branches[p.branch_id]
      if data[branch][center]
        group = groups[p.client_group_id]
        data[branch][center][group] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        if p.ptype==1
          data[branch][center][group][3] += p.amount.round(2)
        elsif p.ptype==2
          data[branch][center][group][4] += p.amount.round(2)
        elsif p.ptype==3
          data[branch][center][group][5] += p.amount.round(2)
        end
      end
    }

    #1: Applied on
    hash = {:applied_on => date, :fields => [:id, :amount, :amount_applied_for, :client_id]}
    hash[:loan_product_id] = loan_product_id if loan_product_id
    Loan.all(hash).each{|l|
      client    = clients[l.client_id]
      next unless client
      next if not center = centers[client.center_id]
      branch = branches[center.branch_id]
      group = groups[client.client_group_id]
      data[branch][center][group] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
      data[branch][center][group][0] += l.amount_applied_for||l.amount
    }

    #2: Approved on
    hash = {:approved_on => date}
    hash[:loan_product_id] = loan_product_id if loan_product_id
    Loan.all(hash).each{|l|
      client    = clients[l.client_id]
      next unless client
      next if not center = centers[client.center_id]
      branch = branches[center.branch_id]
      group = groups[client.client_group_id]
      data[branch][center][group] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
      data[branch][center][group][1] += l.amount_sanctioned||l.amount
    }

    #3: Disbursal date
    hash = {:disbursal_date => date}
    hash[:loan_product_id] = loan_product_id if loan_product_id
    Loan.all(hash).each{|l|
      client    = clients[l.client_id]
      next unless client
      next if not center = centers[client.center_id]
      branch = branches[center.branch_id]
      group = groups[client.client_group_id]
      data[branch][center][group] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
      data[branch][center][group][2] += l.amount
    }
    return data
  end
end
