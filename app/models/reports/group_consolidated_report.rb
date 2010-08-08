class GroupConsolidatedReport < Report
  attr_accessor :from_date, :to_date, :branch, :center, :branch_id, :center_id, :staff_member_id, :loan_product_id

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name   = "Report from #{@from_date} to #{@to_date}"
    get_parameters(params, user)
  end
  
  def name
    "Group wise Consolidated Report from #{@from_date} to #{@to_date}"
  end
  
  def self.name
    "Group wise Consolidated report"
  end
  
  def generate
    branches, centers, groups, clients, loans = {}, {}, {}, {}, {}
    histories = LoanHistory.sum_outstanding_by_group(self.from_date, self.to_date, self.loan_product_id)
    @branch.each{|b|
      groups[b.id]||= {}
      branches[b.id] = b
      
      b.centers.each{|c|
        next if @center and not @center.find{|x| x.id==c.id}
        groups[b.id][c.id]||= {}
        centers[c.id]  = c
        c.client_groups.each{|g|
          #0              1                 2                3              4              5     6                  7         8    9,10,11     12         13
          #amount_applied,amount_sanctioned,amount_disbursed,outstanding(p),outstanding(i),total,principal_paidback,interest_,fee_,shortfalls, #defaults, name
          groups[b.id][c.id][g.id] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, g.name]
          history  = histories.find{|x| x.client_group_id==g.id and x.center_id==c.id} if histories
          if history
            principal_scheduled = history.scheduled_outstanding_principal
            total_scheduled     = history.scheduled_outstanding_total

            principal_actual    = history.actual_outstanding_principal
            total_actual        = history.actual_outstanding_total
            
            principal_advance   = history.advance_principal
            total_advance       = history.advance_total
          else
            principal_scheduled, total_scheduled, principal_actual, total_actual, principal_advance, total_advance = 0, 0, 0, 0, 0, 0
          end

          groups[b.id][c.id][g.id][7] += principal_actual
          groups[b.id][c.id][g.id][9] += total_actual
          groups[b.id][c.id][g.id][8] += total_actual - principal_actual

          groups[b.id][c.id][g.id][10]  += (principal_actual > principal_scheduled ? principal_actual-principal_scheduled : 0)
          groups[b.id][c.id][g.id][11] += ((total_actual-principal_actual) > (total_scheduled-principal_scheduled) ? (total_actual-principal_actual - (total_scheduled-principal_scheduled)) : 0)
          groups[b.id][c.id][g.id][12] += total_actual > total_scheduled ? total_actual - total_scheduled : 0

          groups[b.id][c.id][g.id][13]  += principal_advance
          groups[b.id][c.id][g.id][15] += total_advance
          groups[b.id][c.id][g.id][14] += (total_advance - principal_advance)
        }
      }
    }
    
    center_ids  = centers.keys.length>0 ? centers.keys.join(',') : "NULL"
    repository.adapter.query("select id, center_id, client_group_id from clients where center_id in (#{center_ids}) AND deleted_at is NULL").each{|c|
      clients[c.id] = c
    }
    client_ids = clients.keys.length>0 ? clients.keys.join(',') : "NULL"

    #getting all the loans from the client list above. Filter also by loan product when provided
    query = "l.client_id=c.id and c.center_id in (#{center_ids})"
    query+=" and l.loan_product_id=#{self.loan_product_id}" if self.loan_product_id
    repository.adapter.query("select l.id, l.client_id, l.amount FROM loans l, clients c WHERE #{query}").each{|l|
      loans[l.id] =  l
    }

    repository.adapter.query(%Q{
                               SELECT c.branch_id branch_id, c.id center_id, cl.client_group_id client_group_id, type ptype, SUM(amount) amount
                               FROM payments p, clients cl, centers c
                               WHERE p.received_on >= '#{from_date.strftime('%Y-%m-%d')}' and p.received_on <= '#{to_date.strftime('%Y-%m-%d')}'
                               AND p.deleted_at is NULL AND p.client_id = cl.id AND cl.center_id=c.id AND c.id in (#{center_ids})
                               GROUP BY branch_id, center_id, client_group_id, ptype
                             }).each{|p|
      next if not centers.key?(p.center_id)

      if groups[p.branch_id][p.center_id]
        group_id = p.client_group_id ? p.client_group_id : 0
        groups[p.branch_id][p.center_id][0] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, "No group"] if group_id==0 and not groups[p.branch_id][p.center_id].key?(0)
        if p.ptype==1
          groups[p.branch_id][p.center_id][group_id][3] += p.amount.round(2)
        elsif p.ptype==2
          groups[p.branch_id][p.center_id][group_id][4] += p.amount.round(2)
        elsif p.ptype==3
          groups[p.branch_id][p.center_id][group_id][5] += p.amount.round(2)
        end
      end
    }


    #1: Applied on
    hash = {:applied_on.gte => from_date, :applied_on.lte => to_date, :fields => [:id, :amount, :client_id], :client_id => clients.keys}
    hash[:loan_product_id] = self.loan_product_id if self.loan_product_id

    Loan.all(hash).each{|l|
      client    = clients[l.client_id]
      center_id = client.center_id
      center_id = client.center_id
      next if not centers.key?(center_id)
      branch_id = centers[center_id].branch_id
      groups[branch_id][center_id][0] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, "No group"] if not client.client_group_id and not groups[branch_id][center_id][0]
      groups[branch_id][center_id][client.client_group_id ? client.client_group_id : 0][0] += l.amount_applied_for||l.amount
    }

    #2: Approved on
    hash = {:approved_on.gte => from_date, :approved_on.lte => to_date, :fields => [:id, :amount, :client_id], :client_id => clients.keys}
    hash[:loan_product_id] = self.loan_product_id if self.loan_product_id
    Loan.all(hash).each{|l|
      client    = clients[l.client_id]
      center_id = client.center_id
      next if not centers.key?(center_id)
      branch_id = centers[center_id].branch_id
      groups[branch_id][center_id][0] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, "No group"] if not client.client_group_id and not groups[branch_id][center_id][0]
      groups[branch_id][center_id][client.client_group_id ? client.client_group_id : 0][1] += l.amount_sanctioned||l.amount
    }

    #3: Disbursal date
    hash = {:disbursal_date.gte => from_date, :disbursal_date.lte => to_date, :fields => [:id, :amount, :client_id], :client_id => clients.keys}
    hash[:loan_product_id] = self.loan_product_id if self.loan_product_id
    Loan.all(hash).each{|l|
      client    = clients[l.client_id]
      center_id = client.center_id
      next if not centers.key?(center_id)
      branch_id = centers[center_id].branch_id
      groups[branch_id][center_id][0] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, "No group"] if not client.client_group_id and not groups[branch_id][center_id][0]
      groups[branch_id][center_id][client.client_group_id ? client.client_group_id : 0][2] += l.amount
    }
    return [groups, centers, branches]
  end
end


    # Payment.all(:received_on.gte => from_date, :received_on.lte => to_date, :fields => [:id,:type,:loan_id,:amount,:client_id]).each{|p|
    #   if p.loan_id and loans[p.loan_id] and clients.key?(loans[p.loan_id].client_id)
    #     client = clients[loans[p.loan_id].client_id]
    #   elsif clients.key?(p.client_id)
    #     client = clients[p.client_id]
    #   end
    #   next unless client
    #   center_id = client.center_id
    #   next if not centers.key?(center_id)
    #   branch_id = centers[center_id].branch_id
    #   if groups[branch_id][center_id]
    #     group_id = client.client_group_id ? client.client_group_id : 0
    #     groups[branch_id][center_id][0] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, "No group"] if group_id==0 and not groups[branch_id][center_id].key?(0)
    #     if p.type==:principal
    #       groups[branch_id][center_id][group_id][3] += p.amount
    #     elsif p.type==:interest
    #       groups[branch_id][center_id][group_id][4] += p.amount
    #     elsif p.type==:fees
    #       groups[branch_id][center_id][group_id][5] += p.amount
    #     end
    #   end
    # }
