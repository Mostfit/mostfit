class StaffConsolidatedReport < Report
  attr_accessor :from_date, :to_date, :branch, :center, :branch_id, :center_id, :staff_member_id, :loan_product_id

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name   = "Report from #{@from_date} to #{@to_date}"
    get_parameters(params, user)
  end
  
  def name
    "Consolidated Report for Staff from #{@from_date} to #{@to_date}"
  end
  
  def self.name
    "Consolidated report for Staff"
  end
  
  def generate
    branches, centers, data, staff, clients = {}, {}, {}, {}, {}
    histories = LoanHistory.sum_outstanding_by_center(self.from_date, self.to_date, self.loan_product_id)
    StaffMember.all.each{|s| staff[s.id]=s}
    @branch.each{|b|
      data[b]||= {}
      branches[b.id] = b
      
      b.centers.each{|c|
        cm = c.manager
        next if @center and not @center.find{|x| x.id==c.id}
        data[b][cm]||= {}
        centers[c.id]  = c
        #0              1                 2                3              4              5     6                  7         8    9,10,11     12         13
        #amount_applied,amount_sanctioned,amount_disbursed,outstanding(p),outstanding(i),total,principal_paidback,interest_,fee_,shortfalls, #defaults, name
        data[b][cm][c] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        history  = histories.find{|x| x.center_id==c.id} if histories
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
        
        data[b][cm][c][7] += principal_actual
        data[b][cm][c][9] += total_actual
        data[b][cm][c][8] += total_actual - principal_actual
        
        data[b][cm][c][10]  += (principal_actual > principal_scheduled ? principal_actual-principal_scheduled : 0)
        data[b][cm][c][11] += ((total_actual-principal_actual) > (total_scheduled-principal_scheduled) ? (total_actual-principal_actual - (total_scheduled-principal_scheduled)) : 0)
        data[b][cm][c][12] += total_actual > total_scheduled ? total_actual - total_scheduled : 0
        
        data[b][cm][c][13]  += principal_advance
        data[b][cm][c][15] += total_advance
        data[b][cm][c][14] += (total_advance - principal_advance)
      }
    }

    center_ids  = centers.keys.length>0 ? centers.keys.join(',') : "NULL"
    repository.adapter.query("select id, center_id from clients where center_id in (#{center_ids}) AND deleted_at is NULL").each{|c|
      clients[c.id] = c
    }
    
    extra_condition = ""
    froms = "payments p, clients cl, centers c"
    if self.loan_product_id
      froms+= ", loans l"
      extra_condition = " and p.loan_id=l.id and l.loan_product_id=#{self.loan_product_id}"
    end

    repository.adapter.query(%Q{
                               SELECT p.received_by_staff_id staff_id, c.id center_id, c.branch_id branch_id, type ptype, SUM(p.amount) amount
                               FROM #{froms}
                               WHERE p.received_on >= '#{from_date.strftime('%Y-%m-%d')}' and p.received_on <= '#{to_date.strftime('%Y-%m-%d')}' #{extra_condition}
                               AND p.deleted_at is NULL AND p.client_id=cl.id AND cl.center_id=c.id AND cl.deleted_at is NULL AND c.id in (#{center_ids})
                               GROUP BY staff_id, center_id, p.type
                             }).each{|p|      
      if branch = branches[p.branch_id] and center = centers[p.center_id] and st=staff[p.staff_id]
        data[branch][st] ||= {}
        data[branch][st][center] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        if p.ptype==1
          data[branch][st][center][3] += p.amount.round(2)
        elsif p.ptype==2
          data[branch][st][center][4] += p.amount.round(2)
        elsif p.ptype==3
          data[branch][st][center][5] += p.amount.round(2)
        end
      end
    }
    
    
    #1: Applied on
    hash = {:applied_on.gte => from_date, :applied_on.lte => to_date, :fields => [:id, :amount, :client_id, :applied_by_staff_id]}
    hash[:loan_product_id] = self.loan_product_id if self.loan_product_id
    Loan.all(hash).each{|l|
      next if not clients.key?(l.client_id)
      center_id = clients[l.client_id].center_id
      next if not centers.key?(center_id)
      center = centers[center_id]
      branch = branches[center.branch_id]
      st= staff[l.applied_by_staff_id]

      data[branch][st] ||= {}
      data[branch][st][center] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
      data[branch][st][center][0] += l.amount_applied_for||l.amount
    }

    #2: Approved on
    hash = {:approved_on.gte => from_date, :approved_on.lte => to_date, :fields => [:id, :amount, :client_id, :approved_by_staff_id], :rejected_on => nil}
    hash[:loan_product_id] = self.loan_product_id if self.loan_product_id
    Loan.all(hash).each{|l|
      next if not clients.key?(l.client_id)
      center_id = clients[l.client_id].center_id
      next if not centers.key?(center_id)
      center = centers[center_id]
      branch = branches[center.branch_id]
      st= staff[l.approved_by_staff_id]

      data[branch][st] ||= {}
      data[branch][st][center] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
      data[branch][st][center][1] += l.amount_sanctioned||l.amount
    }

    #3: Disbursal date
    hash = {:disbursal_date.gte => from_date, :disbursal_date.lte => to_date, :fields => [:id, :amount, :client_id, :disbursed_by_staff_id], :rejected_on => nil}
    hash[:loan_product_id] = self.loan_product_id if self.loan_product_id
    Loan.all(hash).each{|l|
      next if not clients.key?(l.client_id)
      center_id = clients[l.client_id].center_id
      next if not centers.key?(center_id)
      center = centers[center_id]
      branch = branches[center.branch_id]
      st= staff[l.disbursed_by_staff_id]

      data[branch][st] ||= {}
      data[branch][st][center] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
      data[branch][st][center][2] += l.amount
    }
    return data
  end
end
