class ConsolidatedReport < Report
  attr_accessor :from_date, :to_date, :branch, :center, :funder, :branch_id, :center_id, :staff_member_id, :loan_product_id, :funder_id, :report_by_loan_disbursed, :funding_line, :funding_line_id, :loan_cycle

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
    extra, funder_loan_ids = get_extra

    grouper = [:branch]    
    grouper.push(:center) if self.branch_id
    group_by_column = (grouper.last.to_s + "_id").to_sym
    
    histories = (LoanHistory.sum_outstanding_grouped_by(self.to_date, grouper, extra)||{}).group_by{|x| x.send(group_by_column)}
    advances  = (LoanHistory.sum_advance_payment(self.from_date, self.to_date, grouper, extra)||{}).group_by{|x| x.send(group_by_column)}
    balances  = (LoanHistory.advance_balance(self.to_date, grouper, extra)||{}).group_by{|x| x.send(group_by_column)}
    old_balances = (LoanHistory.advance_balance(self.from_date-1, grouper, extra)||{}).group_by{|x| x.send(group_by_column)}
    defaults   = LoanHistory.defaulted_loan_info_by(grouper, @to_date, extra).group_by{|x| x.send(group_by_column)}.map{|cid, row| [cid, row[0]]}.to_hash
    
    @center.each{|c| centers[c.id] = c} if self.branch_id

    @branch.each{|b|
      branches[b.id] = b
      
      if self.branch_id
        data[b]||= {}
        b.centers.each{|c|
          next unless centers.key?(c.id)
          centers[c.id]  = c
          add_outstanding_to(data[b], c, histories, advances, balances, old_balances, defaults)
        }      
      else
        #0              1                 2                3              4              5     6                  7         8    9,10,11     12       
        #amount_applied,amount_sanctioned,amount_disbursed,outstanding(p),outstanding(i),total,principal_paidback,interest_,fee_,shortfalls, #defaults
        add_outstanding_to(data, b, histories, advances, balances, old_balances, defaults)
      end
    }

    froms, extra_condition, extra_selects = get_payment_extra_and_froms(centers, funder_loan_ids)
    repository.adapter.query(%Q{
                               SELECT p.received_by_staff_id staff_id, c.branch_id branch_id, type ptype, SUM(p.amount) amount #{extra_selects}
                               FROM #{froms}
                               WHERE p.received_on >='#{from_date.strftime('%Y-%m-%d')}' and p.received_on <= '#{to_date.strftime('%Y-%m-%d')}'AND p.deleted_at is NULL
                                     AND cl.center_id=c.id AND cl.deleted_at is NULL AND p.client_id=cl.id #{extra_condition}
                               GROUP BY #{group_by_column}, p.type
                             }).each{|p|      
      if branch = branches[p.branch_id] 
        if self.branch_id and center = centers[p.center_id]
          add_payments_to(data[branch], center, p)
        else
          add_payments_to(data, branch, p)
        end
      end
    }

    # Applied on, Approved on, Disbursed on
    {:applied_on => [:amount_applied_for, 0], :approved_on => [:amount_sanctioned, 1], :disbursal_date => [:amount, 2]}.each do |event, cols|
      hash = {event.gte => from_date, event.lte => to_date}
      hash[:loan_product_id] = self.loan_product_id if self.loan_product_id
      hash["l.id"]           = funder_loan_ids if funder_loan_ids and funder_loan_ids.length > 0      
      hash["l.cycle_number"] = @loan_cycle if @loan_cycle and not @loan_cycle.nil?
      group_by_query = (self.branch_id ? "c.branch_id, cl.center_id" : "c.branch_id")
      
      group_loans(group_by_query, "sum(if(#{cols[0]}>0, #{cols[0]}, amount)) amount", hash).group_by{|x| 
        x.branch_id
      }.each{|branch_id, center_rows|
        next if not branches.key?(branch_id)
        branch = branches[branch_id]
        
        if self.branch_id
          center_rows.group_by{|x| x.center_id}.each{|center_id, row|        
            next if not centers.key?(center_id)
            center = centers[center_id]
            add_to_result(data[branch], center, cols[1], row[0].amount) if row[0] and row[0].amount
          }
        else
          add_to_result(data, branch, cols[1], center_rows[0].amount) if center_rows[0] and center_rows[0].amount
        end
      }
    end          
    return data
  end

  private
  # This function adds corresponding rows of 'obj' in histories, advances, balances etc 
  # to data hash at key obj.
  def add_outstanding_to(data, obj, histories, advances, balances, old_balances, defaults)
    #0              1                 2                3              4              5     6                  7         8    9,10,11     12       
    #amount_applied,amount_sanctioned,amount_disbursed,outstanding(p),outstanding(i),total,principal_paidback,interest_,fee_,shortfalls, #defaults
    history  = histories[obj.id][0]       if histories.key?(obj.id)
    advance  = advances[obj.id][0]        if advances.key?(obj.id)
    balance  = balances[obj.id][0]        if balances.key?(obj.id)
    old_balance = old_balances[obj.id][0] if old_balances.key?(obj.id)
    
    if history
      principal_scheduled = history.scheduled_outstanding_principal
      total_scheduled     = history.scheduled_outstanding_total
      
      principal_actual    = history.actual_outstanding_principal
      total_actual        = history.actual_outstanding_total
    else
      return
    end
    
    add_to_result(data, obj, 7, principal_actual)
    add_to_result(data, obj, 9, total_actual)
    add_to_result(data, obj, 8, total_actual - principal_actual)

    #overdue
    if defaults[obj.id]
      add_to_result(data, obj, 10, defaults[obj.id].pdiff)
      add_to_result(data, obj, 12, defaults[obj.id].tdiff)
      add_to_result(data, obj, 11, defaults[obj.id].tdiff - defaults[obj.id].pdiff)
    end
    
    new_advance         = advance ? advance.advance_total : 0
    new_advance_balance = balance ? balance.balance_total : 0
    old_advance_balance = old_balance ? old_balance.balance_total : 0
    #advance
    add_to_result(data, obj, 13, new_advance)
    add_to_result(data, obj, 14, new_advance + old_advance_balance - new_advance_balance )
    add_to_result(data, obj, 15, new_advance_balance)
    data
  end 

  def add_payments_to(data, obj, p)
    if p.ptype==1
      add_to_result(data, obj, 3, p.amount.round(2))
    elsif p.ptype==2
      add_to_result(data, obj, 4, p.amount.round(2))
    elsif p.ptype==3
      add_to_result(data, obj, 5, p.amount.round(2))
    end
    data[obj][6] = data[obj][3] + data[obj][4] + data[obj][5]
    data
  end

  # data[obj][column] => value
  def add_to_result(data, obj, column, value)
    data[obj] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    data[obj][column] ||= 0
    data[obj][column] += value
  end
end
