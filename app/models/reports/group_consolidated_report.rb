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
    branches, centers, data, clients, loans, groups = {}, {}, {}, {}, {}, {}
    histories = LoanHistory.sum_outstanding_by_group(self.from_date, self.to_date, self.loan_product_id)
    @branch.each{|b|
      data[b]||= {}
      branches[b.id] = b
      
      b.centers.each{|c|
        next if @center and not @center.find{|x| x.id==c.id}
        data[b][c]||= {}
        centers[c.id]  = c
        c.client_groups.each{|g|
          #0              1                 2                3              4              5     6                  7         8    9,10,11     12         13          
          #amount_applied,amount_sanctioned,amount_disbursed,outstanding(p),outstanding(i),total,principal_paidback,interest_,fee_,shortfalls, #defaults, name
          data[b][c][g] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
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

          data[b][c][g][7] += principal_actual
          data[b][c][g][9] += total_actual
          data[b][c][g][8] += total_actual - principal_actual
          data[b][c][g][10]+= (principal_actual > principal_scheduled ? principal_actual-principal_scheduled : 0)
          data[b][c][g][11]+= ((total_actual-principal_actual) > (total_scheduled-principal_scheduled) ? (total_actual-principal_actual - (total_scheduled-principal_scheduled)) : 0)
          data[b][c][g][12] += total_actual > total_scheduled ? total_actual - total_scheduled : 0

          data[b][c][g][13]  += principal_advance
          data[b][c][g][15] += total_advance
          data[b][c][g][14] += (total_advance - principal_advance)
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
                               WHERE p.received_on >= '#{from_date.strftime('%Y-%m-%d')}' and p.received_on <= '#{to_date.strftime('%Y-%m-%d')}'
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
    hash = {:applied_on.gte => from_date, :applied_on.lte => to_date, :fields => [:id, :amount, :client_id]}
    hash[:loan_product_id] = self.loan_product_id if self.loan_product_id

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
    hash = {:approved_on.gte => from_date, :approved_on.lte => to_date, :fields => [:id, :amount, :client_id], :rejected_on => nil}
    hash[:loan_product_id] = self.loan_product_id if self.loan_product_id
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
    hash = {:disbursal_date.gte => from_date, :disbursal_date.lte => to_date, :fields => [:id, :amount, :client_id], :rejected_on => nil}
    hash[:loan_product_id] = self.loan_product_id if self.loan_product_id
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
