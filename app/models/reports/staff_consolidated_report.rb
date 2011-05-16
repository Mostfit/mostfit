class StaffConsolidatedReport < Report
  attr_accessor :from_date, :to_date, :branch, :center, :branch_id, :center_id, :staff_member_id, :loan_product_id, :funder_id, :report_by_loans_created, :report_by_loan_disbursed_during_selected_date_range, :funding_line, :funding_line_id, :loan_cycle

  validates_with_method :from_date, :date_should_not_be_in_future

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

    extra     = []
    extra    << "l.loan_product_id = #{loan_product_id}" if loan_product_id
    extra    << "lh.branch_id in (#{@branch.map{|b| b.id}.join(', ')})" if @branch.length > 0
    extra    << "lh.center_id in (#{@center.map{|c| c.id}.join(', ')})" if @center.length > 0

    if @report_by_loan_disbursed_during_selected_date_range == 1
      extra    << "l.disbursal_date >='#{from_date.strftime('%Y-%m-%d')}' and l.disbursal_date <='#{to_date.strftime('%Y-%m-%d')}'"
    end

    # if a funder is selected
    if @funder
      funder_loan_ids = @funder.loan_ids
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
    advances  = (LoanHistory.sum_advance_payment(self.from_date, self.to_date, :center, extra)||{}).group_by{|x| x.center_id}
    balances  = (LoanHistory.advance_balance(self.to_date, :center, extra)||{}).group_by{|x| x.center_id}
    old_balances = (LoanHistory.advance_balance(self.from_date-1, :center, extra)||{}).group_by{|x| x.center_id}

    StaffMember.all.each{|s| staff[s.id]=s}
    @center.each{|c| centers[c.id] = c}

    @branch.each{|b|
      data[b]||= {}
      branches[b.id] = b
      
      b.centers.each{|c|
        cm = c.manager
        next unless centers.key?(c.id)
        data[b][cm]||= {}
        #0              1                 2                3              4              5     6                  7         8    9,10,11     12         13
        #amount_applied,amount_sanctioned,amount_disbursed,outstanding(p),outstanding(i),total,principal_paidback,interest_,fee_,shortfalls, #defaults, name
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
        
        data[b][cm][c] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

        data[b][cm][c][7] += principal_actual
        data[b][cm][c][9] += total_actual
        data[b][cm][c][8] += total_actual - principal_actual
        
        data[b][cm][c][10]  += (principal_actual > principal_scheduled ? principal_actual-principal_scheduled : 0)
        data[b][cm][c][11] += ((total_actual-principal_actual) > (total_scheduled-principal_scheduled) ? (total_actual-principal_actual - (total_scheduled-principal_scheduled)) : 0)
        data[b][cm][c][12] += total_actual > total_scheduled ? total_actual - total_scheduled : 0
        
        advance_total = advance ? advance.advance_total : 0
        balance_total = balance ? balance.balance_total : 0
        old_balance_total = old_balance ? old_balance.balance_total : 0
        
        data[b][cm][c][13]  += advance_total
        data[b][cm][c][15]  += balance_total
        data[b][cm][c][14]  += advance_total - balance_total + old_balance_total
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

    staff_id_col  = (report_by_loans_created == 1 ? "p.received_by_staff_id" : "c.manager_staff_id")
    repository.adapter.query(%Q{
                               SELECT #{staff_id_col} staff_id, c.id center_id, c.branch_id branch_id, type ptype, SUM(p.amount) amount
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
    hash = {:center_id => centers.keys}
    hash[:loan_product_id] = self.loan_product_id if self.loan_product_id
    hash[:loan_product_id] = self.loan_product_id if self.loan_product_id
    hash[:id]              = funder_loan_ids if funder_loan_ids and funder_loan_ids.length > 0

    group_by  = (report_by_loans_created == 1 ? [:branch, :staff_member, :center] : [:branch, :center])

    LoanHistory.sum_applied_grouped_by(group_by, from_date, to_date, hash).each{|l|
      next if not centers.key?(l.center_id)
      center = centers[l.center_id]
      branch = branches[l.branch_id]
      st     = (report_by_loans_created == 1 ? staff[l.applied_by_staff_id] : staff[center.manager_staff_id])

      data[branch][st] ||= {}
      data[branch][st][center] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
      data[branch][st][center][0] += l.loan_amount
    }

    #2: Approved on
    LoanHistory.sum_approved_grouped_by(group_by, from_date, to_date, hash).each{|l|
      next if not centers.key?(l.center_id)
      center = centers[l.center_id]
      branch = branches[l.branch_id]
      st     = (report_by_loans_created == 1 ? staff[l.approved_by_staff_id] : staff[center.manager_staff_id])

      data[branch][st] ||= {}
      data[branch][st][center] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
      data[branch][st][center][1] += l.loan_amount
    }

    #3: Disbursal date
    LoanHistory.sum_disbursed_grouped_by(group_by, from_date, to_date, hash).each{|l|
      next if not centers.key?(l.center_id)
      center = centers[l.center_id]
      branch = branches[l.branch_id]
      st     = (report_by_loans_created == 1 ? staff[l.disbursed_by_staff_id] : staff[center.manager_staff_id])

      data[branch][st] ||= {}
      data[branch][st][center] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
      data[branch][st][center][2] += l.loan_amount
    }
    return data
  end
end
