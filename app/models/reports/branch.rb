 module Reporting
  module BranchReports
    # we must convert each SQL struct into a hash of {:branch_id => :value}, so that we are always looking at 
    # the correct branch, and we have to refactor the divison, multiplication, etc. of these arrays
    def query_as_hash(sql)
      # we cache the values to avoid unneccessary calls to the database.
      #calling_method = caller[0].split("`")[1][0..-2]
      #Merb.logger.error! "Called by #{calling_method}"
      #o = Kernel.instance_variable_get("@_#{calling_method}")
      #return o if o
      #puts sql
      o = repository.adapter.query(sql).map {|x| [x[0],x[1]]}.to_hash
      #Kernel.instance_variable_set("@_#{calling_method}",o)
      o
    end
    
    def center_count(start_date=Date.min_date, end_date = Date.today)
      query_as_hash(%Q{
          SELECT b.id, COUNT(c.id) as count
          FROM centers c, branches b
          WHERE c.branch_id = b.id and c.creation_date >= '#{start_date.strftime('%Y-%m-%d')}' 
                                   and c.creation_date <= '#{end_date.strftime('%Y-%m-%d')}'
          GROUP BY b.id})            
    end
    
    def client_count(date = Date.today)
      query_as_hash(%Q{
          SELECT b.id, COUNT(cl.id) as count
          FROM clients cl, centers c, branches b
          WHERE cl.center_id = c.id AND cl.date_joined <= '#{date.strftime('%Y-%m-%d')}' AND c.branch_id = b.id 
                                    AND deleted_at is NULL
          GROUP BY b.id})            
    end
    
    def loan_count(date = Date.today)
      query_as_hash(%Q{
          SELECT b.id, COUNT(l.id) 
          FROM loans l, clients cl, centers c, branches b
          WHERE l.client_id = cl.id AND cl.center_id = c.id AND c.branch_id = b.id AND l.rejected_on is NULL
                                    AND l.disbursal_date <='#{date.strftime('%Y-%m-%d')}' AND l.deleted_at is NULL
                                    AND cl.deleted_at is NULL
          GROUP BY b.id})
    end
    
    def loan_amount(date = Date.today)
      query_as_hash(%Q{
          SELECT b.id, SUM(l.amount) 
          FROM loans l, clients cl, centers c, branches b
          WHERE l.client_id = cl.id AND cl.center_id = c.id AND c.branch_id = b.id AND l.rejected_on is NULL
                                    AND l.disbursal_date <='#{date.strftime('%Y-%m-%d')}' AND l.deleted_at is NULL
                                    AND cl.deleted_at is NULL
          GROUP BY b.id})
    end
    
    def active_client_count(date = Date.today)
      ids = repository.adapter.query(%Q{
                  SELECT loan_id, max(date) date
                  FROM loan_history lh, clients cl, loans l
                  WHERE lh.client_id=cl.id AND cl.date_joined <= '#{date.strftime('%Y-%m-%d')}' AND lh.status in (5,6,7,8,9)
                        AND lh.loan_id=l.id AND l.rejected_on is NULL AND l.deleted_at is NULL
                  GROUP BY loan_id}).collect{|x| "(#{x.loan_id}, '#{x.date.strftime('%Y-%m-%d')}')"}.join(",")
      return false if ids.length==0     
      query_as_hash(%Q{
        SELECT branch_id, count(DISTINCT(client_id))
        FROM loan_history lh
        WHERE (loan_id, date) in (#{ids}) AND status in (5,6)
        GROUP BY branch_id
      })
    end
    
    def dormant_client_count(date = Date.today)
      client_count(date) - active_client_count(date)
    end
    
    def borrower_clients_count(date)
      query_as_hash(%Q{
                       SELECT b.id, COUNT(DISTINCT(client_id)) as count
                       FROM clients cl, loans l, branches b, centers c
                       WHERE cl.id = l.client_id AND cl.active = true AND l.disbursal_date is not NULL 
                                                 AND cl.date_joined <= '#{date.strftime('%Y-%m-%d')}' AND c.branch_id = b.id 
                                                 AND cl.center_id = c.id AND l.deleted_at is NULL AND l.rejected_on is NULL
                       GROUP BY b.id
      })
    end
    
    def client_count_by_loan_cycle(loan_cycle, date=Date.today)
      # this simply counts the number of loans for a given client without taking into account the status of those loans.
      query_as_hash(%Q{
            SELECT b.id, COUNT(l.id) 
            FROM branches b, centers c, clients cl, loans l
            WHERE b.id=c.branch_id AND cl.center_id=c.id AND cl.deleted_at is NULL AND cl.id=l.client_id AND l.deleted_at is NULL
                  AND l.disbursal_date<='#{date.strftime('%Y-%m-%d')}' AND cycle_number='#{loan_cycle}' AND l.rejected_on is NULL
            GROUP BY b.id})
    end
    
    def clients_added_between(start_date, end_date)
      start_date = Date.parse(start_date) unless start_date.is_a? Date
      end_date = Date.parse(end_date) unless end_date.is_a? Date
      query_as_hash(%Q{
        SELECT b.id, COUNT(c.id) 
        FROM clients c, centers ce, branches b
        WHERE date_joined BETWEEN '#{start_date.strftime('%Y-%m-%d')}' AND '#{end_date.strftime('%Y-%m-%d')}'
        AND c.center_id = ce.id AND ce.branch_id = b.id
        GROUP BY b.id})
    end
    
    def clients_deleted_between(start_date, end_date)
      start_date = Date.parse(start_date) unless start_date.is_a? Date
      end_date = Date.parse(end_date) unless end_date.is_a? Date
      query_as_hash(%Q{
        SELECT b.id, COUNT(c.id) 
        FROM clients c, centers ce, branches b
        WHERE deleted_at BETWEEN '#{start_date.strftime('%Y-%m-%d')}' AND '#{end_date.strftime('%Y-%m-%d')}'
              AND c.center_id = ce.id AND ce.branch_id = b.id
        GROUP BY b.id})
    end
    
    def loans_repaid_between(start_date, end_date, what)
      start_date = Date.parse(start_date) unless start_date.is_a? Date
      end_date = Date.parse(end_date) unless end_date.is_a? Date
      return unless what.downcase == "sum" or what.downcase == "count"
      query_as_hash(%Q{
         SELECT lh.branch_id, #{what}(l.amount)
         FROM loans l, loan_history lh
         WHERE l.id = lh.loan_id 
               AND  lh.status = #{STATUSES.index(:repaid) + 1}  AND lh.date BETWEEN '#{start_date.strftime('%Y-%m-%d')}' 
               AND '#{end_date.strftime('%Y-%m-%d')}'
               AND  l.deleted_at is NULL AND l.rejected_on is NULL
         GROUP BY lh.branch_id})
    end
    
    def loans_disbursed_between(start_date, end_date, what)
      start_date = Date.parse(start_date) unless start_date.is_a? Date
      end_date = Date.parse(end_date) unless end_date.is_a? Date
      return unless what.downcase == "sum" or what.downcase == "count"
        query_as_hash(%Q{
         SELECT lh.branch_id, #{what}(l.amount)
         FROM loans l, loan_history lh
         WHERE l.id = lh.loan_id 
               AND  lh.status = #{STATUSES.index(:disbursed) + 1} AND  lh.date BETWEEN '#{start_date.strftime('%Y-%m-%d')}' 
               AND '#{end_date.strftime('%Y-%m-%d')}' AND l.deleted_at is NULL AND l.rejected_on is NULL
         GROUP BY lh.branch_id})
    end
    
    def loans_applied_between(start_date, end_date, what)
      start_date = Date.parse(start_date) unless start_date.is_a? Date
      end_date = Date.parse(end_date) unless end_date.is_a? Date
      return unless what.downcase == "sum" or what.downcase == "count"
      query_as_hash(%Q{
         SELECT c.branch_id branch_id, #{what}(if(l.amount_applied_for>0, l.amount_applied_for, l.amount))
         FROM loans l, clients cl, centers c
         WHERE l.client_id = cl.id AND cl.center_id=c.id AND l.applied_on BETWEEN '#{start_date.strftime('%Y-%m-%d')}' 
                                   AND '#{end_date.strftime('%Y-%m-%d')}' 
               AND l.deleted_at is NULL AND l.rejected_on is NULL
         GROUP BY c.branch_id})
    end
    
    def loans_approved_between(start_date, end_date, what)
      start_date = Date.parse(start_date) unless start_date.is_a? Date
      end_date = Date.parse(end_date) unless end_date.is_a? Date
      return unless what.downcase == "sum" or what.downcase == "count"
      query_as_hash(%Q{
         SELECT c.branch_id branch_id, #{what}(if(amount_sanctioned > 0, amount_sanctioned, amount))
         FROM loans l, clients cl, centers c
         WHERE l.client_id = cl.id AND cl.center_id=c.id AND l.approved_on BETWEEN '#{start_date.strftime('%Y-%m-%d')}' 
                                   AND '#{end_date.strftime('%Y-%m-%d')}' 
                                   AND l.deleted_at is NULL AND l.rejected_on is NULL
         GROUP BY c.branch_id})
    end
    
    [:principal, :interest, :fees].each_with_index do |payment_type, ptype|
      query_type = :received
      define_method("#{payment_type}_#{query_type}_between") do |start_date, end_date|
        repository.adapter.query(%Q{SELECT branch_id, sum(amount) amount FROM payments p, clients cl, centers c, branches b 
                                      WHERE b.id=c.branch_id AND cl.center_id=c.id AND p.client_id=cl.id AND p.deleted_at is NULL 
                                                             AND cl.deleted_at is NULL 
                                                             AND p.type=#{ptype+1} 
                                                             AND p.received_on>='#{start_date.strftime('%Y-%m-%d')}'
                                                             AND p.received_on<='#{end_date.strftime('%Y-%m-%d')}' 
                                      GROUP BY b.id;}).group_by{|x| x[0]}.map{|b, a| 
          {b => a[0].amount.to_i}
        }.inject({}){|s,x| s+=x}
      end
    end
    
    def principal_due_between(start_date, end_date)
      get_latest_before(:scheduled_outstanding_principal, start_date) - get_latest_before(:scheduled_outstanding_principal, end_date) + loans_disbursed_between(start_date, end_date, "sum")
    end
    
    def total_due_between(start_date, end_date)
      get_latest_before(:scheduled_outstanding_total, start_date) - get_latest_before(:scheduled_outstanding_total, end_date) + loans_disbursed_between(start_date, end_date, "sum")
    end
    
    def interest_due_between(start_date, end_date)
      total_due_between(start_date, end_date) - principal_due_between(start_date, end_date)
    end    
    
    def principal_outstanding(date = Date.today)
      date = Date.parse(date) unless date.is_a? Date
      LoanHistory.sum_outstanding_grouped_by(date, :branch).find{|x| x.branch_id==3}
      get_latest_before(:actual_outstanding_principal, date)
    end
    
    def principal_amount(date = Date.today)
      query_as_hash(%Q{SELECT b.id, 
                       SUM(p.amount) amount 
                       FROM payments p, loans l, clients cl, centers c, branches b 
                       WHERE p.type=1 AND p.deleted_at is NULL AND p.loan_id=l.id AND p.received_on <= '#{date.strftime('%Y-%m-%d')}'
                                      AND l.client_id=cl.id AND cl.center_id=c.id AND c.branch_id=b.id 
                       GROUP BY b.id})
    end
    
    def interest_amount(date = Date.today)
      query_as_hash(%Q{SELECT b.id, 
                       SUM(p.amount) amount 
                       FROM payments p, loans l, clients cl, centers c, branches b 
                       WHERE p.type=2 AND p.loan_id=l.id AND p.deleted_at is NULL AND p.received_on <= '#{date.strftime('%Y-%m-%d')}'
                                      AND l.client_id=cl.id AND cl.center_id=c.id AND c.branch_id=b.id 
                       GROUP BY b.id})
    end
    
    def income(date = Date.today)
      interest_amount(date) + fee_received(date)
    end

    def fee_received(date)
      loan_fee(date)+card_fee(date)
    end
  
    def fee_received_between(start_date, end_date)
      start_date = Date.parse(start_date) unless start_date.is_a? Date
      end_date = Date.parse(end_date) unless end_date.is_a? Date
      query_as_hash(%Q{SELECT b.id, 
                       SUM(p.amount) amount 
                       FROM payments p, clients cl, centers c, branches b
                       WHERE p.type=3 AND p.client_id=cl.id AND p.deleted_at is NULL  
                                      AND p.received_on >= '#{start_date.strftime('%Y-%m-%d')}' 
                                      AND p.received_on <= '#{end_date.strftime('%Y-%m-%d')}' 
                                      AND cl.center_id=c.id AND c.branch_id=b.id
                       GROUP BY b.id})
    end
    
    def card_fee(date)
      query_as_hash(%Q{SELECT b.id, 
                       SUM(p.amount) amount
                       FROM payments p, clients cl, centers c, branches b
                       WHERE p.type=3 AND p.deleted_at IS NULL AND p.loan_id IS NULL AND p.client_id=cl.id
                                      AND p.received_on <= '#{date.strftime('%Y-%m-%d')}'
                                      AND cl.center_id=c.id AND cl.deleted_at is NULL 
                                      AND c.branch_id=b.id
                       GROUP BY b.id})
    end
    
    def loan_fee(date)
      query_as_hash(%Q{
                       SELECT b.id, 
                       SUM(p.amount) amount 
                       FROM payments p, loans l, clients cl, centers c, branches b 
                       WHERE p.type=3 AND p.loan_id=l.id AND cl.deleted_at is NULL AND p.deleted_at IS NULL
                                      AND p.received_on <= '#{date.strftime('%Y-%m-%d')}'
                                      AND p.loan_id IS NOT NULL AND l.client_id=cl.id AND cl.center_id=c.id 
                                      AND c.branch_id=b.id
                       GROUP BY b.id})
    end
    
    def scheduled_principal_outstanding(date = Date.today)
      date = Date.parse(date) unless date.is_a? Date
      get_latest_before(:scheduled_outstanding_principal, date)
    end
    
    def total_outstanding(date = Date.today)
      date = Date.parse(date) unless date.is_a? Date
      get_latest_before(:actual_outstanding_total, date)
    end
    
    def scheduled_total_outstanding(date = Date.today)
      date = Date.parse(date) unless date.is_a? Date
      get_latest_before(:scheduled_outstanding_total, date)
    end
    
    def center_managers_count(date)
      query_as_hash(%Q{SELECT branch_id, count(distinct(manager_staff_id)) FROM centers GROUP BY branch_id})
    end
    
    def client_groups_count(date = Date.today)
      query_as_hash(%Q{ 
          SELECT b.id, COUNT(*) as count
          FROM client_groups clg, centers c, branches b
          WHERE clg.center_id = c.id AND c.branch_id = b.id
          GROUP BY b.id})
    end
    
    def avg_outstanding_balance_per_client(date)
      po = principal_outstanding(date)
      cc = client_count(date)
      summary = po.values.inject(0){|sum, a| sum+a} / cc.values.inject(0){|sum, a| sum+a}
      (po/cc).merge( {:summary => summary})
    end
    
    def avg_outstanding_balance_per_cm(date)
      po = principal_outstanding(date)
      cm = center_managers_count(date)
      summary = po.values.inject(0){|sum, a| sum+a} / cm.values.inject(0){|sum, a| sum+a}
      (po/cm).merge( {:summary => summary})
    end
    
    def avg_loan_size_per_cm(date)
      la = loan_amount(date)
      cm = center_managers_count(date)
      summary = la.values.inject(0){|sum, a| sum+a} / cm.values.inject(0){|sum, a| sum+a}
      (la/cm).merge( {:summary => summary})
    end
    
    def avg_loan_size_per_client(date)
      la = loan_amount(date)
      cc = client_count(date)
      summary = la.values.inject(0){|sum, a| sum+a} / cc.values.inject(0){|sum, a| sum+a}
      (la/cc).merge( {:summary => summary})
    end

    def principal_overdue_by(date=Date.today)
      Branch.all.map{|b| 
        due = LoanHistory.defaulted_loan_info_for(b, date)
        if due
          [b.id, due.principal_due.to_i]
        else
          [b.id, 0]
        end
      }.to_hash
    end
    
    def additional_principal_overdue_last_week(start_date=Date.today, end_date =Date.today)
      added_overdue = Branch.principal_overdue_by(end_date) - Branch.principal_overdue_by(start_date-1)
      added_overdue.values.each do |x|
        x > 0 ? x : 0 
      end
      added_overdue.to_hash
    end
    
    def overpaid_principal_between(start_date=Date.today, end_date=Date.today)
      LoanHistory.sum_advance_payment(start_date, end_date, :branch).group_by{|x| x.branch_id}.map{|bid, d| 
        {bid => d.first.advance_principal.to_i}
      }.inject({}){|s,x| s+=x}      
    end
    
    def overpaid_total_between(start_date=Date.today, end_date=Date.today)
      LoanHistory.sum_advance_payment(start_date, end_date, :branch).group_by{|x| x.branch_id}.map{|bid, d| 
        {bid => d.first.advance_total.to_i}
      }.inject({}){|s,x| s+=x}      
    end
    
    def get_latest_loan_history_row_before(date = Date.today)
      date = Date.parse(date) unless date.is_a? Date
      repository.adapter.query("SELECT loan_id, max(date) date FROM loan_history 
                                WHERE date <= '#{date.strftime('%Y-%m-%d')}' AND status in (5,6,7,8) GROUP BY loan_id")
    end
    
    def get_latest_before(column, date = Date.today, group_by = nil)
      date     = Date.parse(date) unless date.is_a? Date
      @os_data = LoanHistory.sum_outstanding_grouped_by(date, :branch).group_by{|x| x.branch_id}
      @os_data.map{|b, d| {b => d.first.send(column).to_i}}.inject({}){|s,x| s+=x}
    end
    
    # def method_missing(name, params)
    #   if /avg_([a-zA-Z0-9_]+)_per_([a-zA-Z0-9_]+)/.match(name.to_s)
    #     num = params ? send($1, *params[0]) : send($1)
    #     den = params ? send($2, *params[1]) : send($2)
    #     return num/den
    #   else
    #     raise NoMethodError
    #   end
    # end
  end
end
