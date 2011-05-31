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
    extra    << "lh.center_id in (#{@center.map{|c| c.id}.join(', ')})" if @center and @center.length > 0 and @center.length != Center.count

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

    grouper = [:branch]    
    grouper.push(:center) if @center
    group_by_column = (grouper.last.to_s + "_id").to_sym
    
    histories = (LoanHistory.sum_outstanding_grouped_by(self.to_date, grouper, extra)||{}).group_by{|x| x.send(group_by_column)}
    advances  = (LoanHistory.sum_advance_payment(self.from_date, self.to_date, grouper, extra)||{}).group_by{|x| x.send(group_by_column)}
    balances  = (LoanHistory.advance_balance(self.to_date, grouper, extra)||{}).group_by{|x| x.send(group_by_column)}
    old_balances = (LoanHistory.advance_balance(self.from_date-1, grouper, extra)||{}).group_by{|x| x.send(group_by_column)}
    defaults   = LoanHistory.defaulted_loan_info_by(grouper, @to_date, extra).group_by{|x| x.send(group_by_column)}.map{|cid, row| [cid, row[0]]}.to_hash
    
    @center.each{|c| centers[c.id] = c} if @center

    @branch.each{|b|
      branches[b.id] = b
      
      if @center
        data[b]||= {}
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
      else
        #0              1                 2                3              4              5     6                  7         8    9,10,11     12       
        #amount_applied,amount_sanctioned,amount_disbursed,outstanding(p),outstanding(i),total,principal_paidback,interest_,fee_,shortfalls, #defaults
        history  = histories[b.id][0]       if histories.key?(b.id)
        advance  = advances[b.id][0]        if advances.key?(b.id)
        balance  = balances[b.id][0]        if balances.key?(b.id)
        old_balance = old_balances[b.id][0] if old_balances.key?(b.id)
        
        if history
          principal_scheduled = history.scheduled_outstanding_principal
          total_scheduled     = history.scheduled_outstanding_total
          
          principal_actual    = history.actual_outstanding_principal
          total_actual        = history.actual_outstanding_total
        else
          next
        end
        
        data[b] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        
        data[b][7] += principal_actual
        data[b][9] += total_actual
        data[b][8] += total_actual - principal_actual

        #overdue
        if defaults[b.id]
          data[b][10] += defaults[b.id].pdiff
          data[b][12] += defaults[b.id].tdiff
          data[b][11] += (data[b][12] - data[b][10])
        end
        
        new_advance         = advance ? advance.advance_total : 0
        new_advance_balance = balance ? balance.balance_total : 0
        old_advance_balance = old_balance ? old_balance.balance_total : 0
        #advance
        data[b][13]  += new_advance
        data[b][14]  += new_advance + old_advance_balance - new_advance_balance 
        data[b][15]  += new_advance_balance
      end
    }

    extra_condition, extra_selects = "", ""
    froms = "payments p, clients cl, centers c"

    if @center
      center_ids  = centers.keys.length>0 ? centers.keys.join(',') : "NULL"
      extra_condition = "AND c.id in (#{center_ids})"
      extra_selects   = ", c.id center_id"
    end

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
                               SELECT p.received_by_staff_id staff_id, c.branch_id branch_id, type ptype, SUM(p.amount) amount #{extra_selects}
                               FROM #{froms}
                               WHERE p.received_on >='#{from_date.strftime('%Y-%m-%d')}' and p.received_on <= '#{to_date.strftime('%Y-%m-%d')}'AND p.deleted_at is NULL
                                     AND cl.center_id=c.id AND cl.deleted_at is NULL AND p.client_id=cl.id #{extra_condition}
                               GROUP BY #{group_by_column}, p.type
                             }).each{|p|      
      if branch = branches[p.branch_id] 
        if @center and center = centers[p.center_id]        
          data[branch][center] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
          if p.ptype==1
            data[branch][center][3] += p.amount.round(2)
          elsif p.ptype==2
            data[branch][center][4] += p.amount.round(2)
          elsif p.ptype==3
            data[branch][center][5] += p.amount.round(2)
          end
        else
          data[branch] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
          if p.ptype==1
            data[branch][3] += p.amount.round(2)
          elsif p.ptype==2
            data[branch][4] += p.amount.round(2)
          elsif p.ptype==3
            data[branch][5] += p.amount.round(2)
          end
          data[branch][6] = data[branch][3] + data[branch][4] + data[branch][5]
        end
      end
    }

    #1: Applied on
    hash = {:applied_on.gte => from_date, :applied_on.lte => to_date}
    hash[:loan_product_id] = self.loan_product_id if self.loan_product_id
    hash["l.id"]           = funder_loan_ids if funder_loan_ids and funder_loan_ids.length > 0
    group_by_query = (@center ? "c.branch_id, cl.center_id" : "c.branch_id")

    group_loans(group_by_query, "sum(if(amount_applied_for>0, amount_applied_for, amount)) amount", hash).group_by{|x| 
      x.branch_id
    }.each{|branch_id, center_rows|
      next if not branches.key?(branch_id)
      branch = branches[branch_id]

      if @center
        center_rows.group_by{|x| x.center_id}.each{|center_id, row|        
          next if not centers.key?(center_id)
          center = centers[center_id]
          data[branch][center] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
          data[branch][center][0] += row[0].amount
        }
      else
        data[branch] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        data[branch][0] += center_rows[0].amount if center_rows[0] and center_rows[0].amount
      end
    }

    #2: Approved on
    hash = {:approved_on.gte => from_date, :approved_on.lte => to_date, :rejected_on => nil}
    hash[:loan_product_id] = self.loan_product_id if self.loan_product_id
    hash["l.id"]              = funder_loan_ids if funder_loan_ids and funder_loan_ids.length > 0

    group_loans(group_by_query, "sum(if(amount_sanctioned > 0, amount_sanctioned, amount)) amount", hash).group_by{|x| 
      x.branch_id
    }.each{|branch_id, center_rows| 
      next if not branches.key?(branch_id)
      branch = branches[branch_id]
      if @center
        center_rows.group_by{|x| x.center_id}.each{|center_id, row|
          next if not centers.key?(center_id)
          center = centers[center_id]
          data[branch][center] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
          data[branch][center][1] += row[0].amount 
        }
      else
        data[branch] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        data[branch][1] += center_rows[0].amount if center_rows[0] and center_rows[0].amount
      end
    }

    #3: Disbursal date
    hash = {:disbursal_date.gte => from_date, :disbursal_date.lte => to_date, :rejected_on => nil}
    hash[:loan_product_id] = self.loan_product_id if self.loan_product_id
    hash["l.id"]           = funder_loan_ids if funder_loan_ids and funder_loan_ids.length > 0

    group_loans(group_by_query, "sum(amount) amount", hash).group_by{|x| 
      x.branch_id
    }.each{|branch_id, center_rows| 
      next if not branches.key?(branch_id)
      branch = branches[branch_id]
      if @center
        center_rows.group_by{|x| x.center_id}.each{|center_id, row|        
          next if not centers.key?(center_id)
          center = centers[center_id]
          data[branch][center] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
          data[branch][center][2] += row[0].amount
        }
      else
        data[branch] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        data[branch][2] += center_rows[0].amount if center_rows[0] and center_rows[0].amount
      end
    }
    return data
  end
end
