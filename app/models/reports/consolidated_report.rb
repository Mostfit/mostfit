class ConsolidatedReport < Report
  attr_accessor :from_date, :to_date, :branch, :center, :funder, :branch_id, :center_id, :staff_member_id, :loan_product_id, :funder_id, :report_by_loan_disbursed_during_selected_date_range, :funding_line, :funding_line_id, :loan_cycle

  validates_with_method :from_date, :date_should_not_be_in_future

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
    extra    << "lh.branch_id in (#{@branch.map{|b| b.id}.join(', ')})" if @branch.length > 0 and @branch.length != Branch.count
    extra    << "lh.center_id in (#{@center.map{|c| c.id}.join(', ')})" if @center.length > 0 and @center.length != Center.count

    if @report_by_loan_disbursed_during_selected_date_range == 1 
      extra    << "l.disbursal_date >='#{from_date.strftime('%Y-%m-%d')}' and l.disbursal_date <='#{to_date.strftime('%Y-%m-%d')}'"
    end

    # if a funder is selected
    if @funder
      funder_loan_ids = @funder.loan_ids
      funder_loan_ids = ["NULL"] if funder_loan_ids.length == 0
      extra    << "l.id in (#{funder_loan_ids.join(", ")})" 
    end

    #if funding_lines are selected
    if @funding_line
      funding_line_ids = @funding_line.funder
      funding_line_ids = ["NULL"] if funding_line_ids.length == 0
      extra   << "l.id in (#{funding_line_ids.join(", ")})"
    end

    #if loan cycle_number is selected
    if @loan_cycle
      lc = @loan_cycle
      lc = ["NULL"] if @loan_cycle.nil?
      extra   << "l.cycle_number = #{lc}"
    end

    histories = (LoanHistory.sum_outstanding_grouped_by(self.to_date, [:branch, :center], extra)||{}).group_by{|x| x.center_id}
    advances  = (LoanHistory.sum_advance_payment(self.from_date, self.to_date, [:branch, :center], extra)||{}).group_by{|x| x.center_id}
    balances  = (LoanHistory.advance_balance(self.to_date, :center, extra)||{}).group_by{|x| x.center_id}
    old_balances = (LoanHistory.advance_balance(self.from_date-1, :center, extra)||{}).group_by{|x| x.center_id}
    defaults   = LoanHistory.defaulted_loan_info_by(:center, @to_date, extra).group_by{|x| x.center_id}.map{|cid, row| [cid, row[0]]}.to_hash

    @center.each{|c| centers[c.id] = c}

    @branch.each{|b|
      data[b]||= {}
      branches[b.id] = b
      
      b.centers.each{|c|
        next unless centers.key?(c.id)
        centers[c.id]  = c
        #0              1                 2                3              4              5     6                  7         8    9,10,11     12       
        #amount_applied,amount_sanctioned,amount_disbursed,outstanding(p),outstanding(i),total,principal_paidback,interest_,fee_,shortfalls, #defaults
        history  = histories[c.id][0]       if histories.key?(c.id)
        advance  = advances[c.id][0]        if advances.key?(c.id)
        balance  = balances[c.id][0]        if balances.key?(c.id)
        old_balance = old_balances[c.id][0] if old_balances.key?(c.id)

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
        #overdue
        if defaults[c.id]
          data[b][c][10] += defaults[c.id].pdiff
          data[b][c][12] += defaults[c.id].tdiff
          data[b][c][11] += (data[b][c][12] - data[b][c][10])
        end

        new_advance         = advance ? advance.advance_total : 0
        new_advance_balance = balance ? balance.balance_total : 0
        old_advance_balance = old_balance ? old_balance.balance_total : 0
        #advance
        data[b][c][13]  += new_advance
        data[b][c][14]  += new_advance + old_advance_balance - new_advance_balance 
        data[b][c][15]  += new_advance_balance
      }
    }
    
    center_ids  = centers.keys.length>0 ? centers.keys.join(',') : "NULL"
    extra_condition = ""
    froms = "payments p, clients cl, centers c"

    if self.loan_product_id
      froms += ", loans l"
      extra_condition = " and p.loan_id=l.id and l.loan_product_id=#{self.loan_product_id}"
    end

    if report_by_loan_disbursed_during_selected_date_range and report_by_loan_disbursed_during_selected_date_range == 1
      froms += ", loans l"
      extra_condition = " and p.loan_id=l.id and l.disbursal_date >='#{from_date.strftime('%Y-%m-%d')}' and l.disbursal_date <='#{to_date.strftime('%Y-%m-%d')}'"
    end
    
    if funder_loan_ids and funder_loan_ids.length > 0
      froms += ", loans l" unless froms.include?(", loans l")
      extra_condition += "and p.loan_id=l.id" unless extra_condition.include?("and p.loan_id=l.id")
      extra_condition += " and l.id in (#{funder_loan_ids.join(', ')})"
    end

    if funding_line_ids and funding_line_ids.length > 0
      froms += ", loans l" unless froms.include?(", loans l")
      extra_condition += "and p.loan_id=l.id" unless extra_condition.include?("and p.loan_id=l.id")
      extra_condition += "and l.id in (#{funding_line_ids.join(', ')})"
    end

    if lc and not lc.nil?
      froms += ", loans l" unless froms.include?(", loans l")
      extra_condition += "and p.loan_id=l.id" unless extra_condition.include?("and p.loan_id=l.id")
      extra_condition += "and l.cycle_number = #{lc}"
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
