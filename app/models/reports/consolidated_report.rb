class ConsolidatedReport < Report
  attr_accessor :from_date, :to_date, :branch, :center, :funder, :branch_id, :center_id, :staff_member_id, :loan_product_id, :funder_id

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name   = "Report from #{@from_date} to #{@to_date}"
    get_parameters(params, user)
  end
  
  def name
    "Center wise Consolidated Report from #{@from_date} to #{@to_date}"
  end
  
  def self.name
    "Center wise Consolidated report"
  end
  
  def generate
    branches, centers, data, clients, loans = {}, {}, {}, {}, {}
    extra     = []
    extra    << "l.loan_product_id = #{loan_product_id}" if loan_product_id
    extra    << "lh.branch_id = #{@branch.first.id}" if @branch.length == 1
    extra    << "lh.center_id = #{@center.first.id}" if @center.length == 1
    # if a funder is selected
    if @funder
      funder_loan_ids = @funder.loan_ids
      funder_loan_ids = ["NULL"] if funder_loan_ids.length == 0
      extra    << "l.id in (#{funder_loan_ids.join(", ")})" 
    end

    histories = LoanHistory.sum_outstanding_grouped_by(self.to_date, [:branch, :center], extra)
    advances  = LoanHistory.sum_advance_payment(self.from_date, self.to_date, [:branch, :center], extra)||[]
    balances  = LoanHistory.advance_balance(self.to_date, :center, extra)||[]
    old_balances = LoanHistory.advance_balance(self.from_date-1, :center, extra)||[]

    @branch.each{|b|
      data[b]||= {}
      branches[b.id] = b
      
      b.centers.each{|c|
        next if @center and not @center.find{|x| x.id==c.id}
        centers[c.id]  = c
        #0              1                 2                3              4              5     6                  7         8    9,10,11     12       
        #amount_applied,amount_sanctioned,amount_disbursed,outstanding(p),outstanding(i),total,principal_paidback,interest_,fee_,shortfalls, #defaults
        history  = histories.find{|x| x.center_id==c.id}
        advance  = advances.find{|x|  x.center_id==c.id}
        balance  = balances.find{|x|  x.center_id==c.id}
        old_balance = old_balances.find{|x|  x.center_id==c.id}

        if history
          principal_scheduled = history.scheduled_outstanding_principal
          total_scheduled     = history.scheduled_outstanding_total
          
          principal_actual    = history.actual_outstanding_principal
          total_actual        = history.actual_outstanding_total
        else
          next
        end

        data[b][c] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        
        data[b][c][7] += principal_actual
        data[b][c][9] += total_actual
        data[b][c][8] += total_actual - principal_actual

        data[b][c][10]  += (principal_actual > principal_scheduled ? principal_actual-principal_scheduled : 0)
        data[b][c][11] += ((total_actual-principal_actual) > (total_scheduled-principal_scheduled) ? (total_actual-principal_actual - (total_scheduled-principal_scheduled)) : 0)
        data[b][c][12] += total_actual > total_scheduled ? total_actual - total_scheduled : 0
        
        advance_total = advance ? advance.advance_total : 0
        balance_total = balance ? balance.balance_total : 0
        old_balance_total = old_balance ? old_balance.balance_total : 0
        
        data[b][c][13]  += advance_total
        data[b][c][15]  += balance_total
        data[b][c][14]  += advance_total - balance_total + old_balance_total
      }
    }
    
    center_ids  = centers.keys.length>0 ? centers.keys.join(',') : "NULL"
    repository.adapter.query("select id, center_id from clients where center_id in (#{center_ids}) AND deleted_at is NULL").each{|c|
      clients[c.id] = c
    }
    
    extra_condition = ""
    froms = "payments p, clients cl, centers c"
    if self.loan_product_id
      froms += ", loans l"
      extra_condition = " and p.loan_id=l.id and l.loan_product_id=#{self.loan_product_id}"
    end
    
    if funder_loan_ids and funder_loan_ids.length > 0
      froms += ", loans l" unless froms.include?(", loans l")
      extra_condition += "and p.loan_id=l.id" unless extra_condition.include?("and p.loan_id=l.id")
      extra_condition += " and l.id in (#{funder_loan_ids.join(', ')})"
    end      

    repository.adapter.query(%Q{
                               SELECT p.received_by_staff_id staff_id, c.id center_id, c.branch_id branch_id, type ptype, SUM(p.amount) amount
                               FROM #{froms}
                               WHERE p.received_on >='#{from_date.strftime('%Y-%m-%d')}' and p.received_on <= '#{to_date.strftime('%Y-%m-%d')}'AND p.deleted_at is NULL
                               AND p.client_id=cl.id AND cl.center_id=c.id AND cl.deleted_at is NULL AND c.id in (#{center_ids})#{extra_condition}
                               GROUP BY center_id, p.type
                             }).each{|p|      
      if branch = branches[p.branch_id] and center = centers[p.center_id]
        data[branch][center] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        if p.ptype==1
          data[branch][center][3] += p.amount.round(2)
        elsif p.ptype==2
          data[branch][center][4] += p.amount.round(2)
        elsif p.ptype==3
          data[branch][center][5] += p.amount.round(2)
        end
      end
    }


    #1: Applied on
    hash = {:applied_on.gte => from_date, :applied_on.lte => to_date}
    hash[:loan_product_id] = self.loan_product_id if self.loan_product_id
    hash["l.id"]           = funder_loan_ids if funder_loan_ids and funder_loan_ids.length > 0

    group_loans("c.branch_id, cl.center_id", "sum(if(amount_applied_for>0, amount_applied_for, amount)) amount", hash).group_by{|x| 
      x.branch_id
    }.each{|branch_id, center_rows| 
      next if not branches.key?(branch_id)
      branch = branches[branch_id]
      center_rows.group_by{|x| x.center_id}.each{|center_id, row|        
        next if not centers.key?(center_id)
        center = centers[center_id]
        data[branch][center] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        data[branch][center][0] += row[0].amount
      }
    }

    #2: Approved on
    hash = {:approved_on.gte => from_date, :approved_on.lte => to_date, :rejected_on => nil}
    hash[:loan_product_id] = self.loan_product_id if self.loan_product_id
    hash["l.id"]              = funder_loan_ids if funder_loan_ids and funder_loan_ids.length > 0

    group_loans("c.branch_id, cl.center_id", "sum(if(amount_sanctioned > 0, amount_sanctioned, amount)) amount", hash).group_by{|x| 
      x.branch_id
    }.each{|branch_id, center_rows| 
      next if not branches.key?(branch_id)
      branch = branches[branch_id]
      center_rows.group_by{|x| x.center_id}.each{|center_id, row|
        next if not centers.key?(center_id)
        center = centers[center_id]
        data[branch][center] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        data[branch][center][1] += row[0].amount
      }
    }

    #3: Disbursal date
    hash = {:disbursal_date.gte => from_date, :disbursal_date.lte => to_date, :rejected_on => nil}
    hash[:loan_product_id] = self.loan_product_id if self.loan_product_id
    hash["l.id"]           = funder_loan_ids if funder_loan_ids and funder_loan_ids.length > 0

    group_loans("c.branch_id, cl.center_id", "sum(amount) amount", hash).group_by{|x| 
      x.branch_id
    }.each{|branch_id, center_rows| 
      next if not branches.key?(branch_id)
      branch = branches[branch_id]
      center_rows.group_by{|x| x.center_id}.each{|center_id, row|        
        next if not centers.key?(center_id)
        center = centers[center_id]
        data[branch][center] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        data[branch][center][2] += row[0].amount
      }
    }
    return data
  end
end
