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

    def client_count(date = Date.today)
      query_as_hash(%Q{
          SELECT b.id, COUNT(cl.id) as count
          FROM clients cl, centers c, branches b
          WHERE cl.center_id = c.id AND c.branch_id = b.id and cl.date_joined < '#{date.strftime('%Y-%m-%d')}' AND deleted_at is NULL
          GROUP BY b.id})            
    end

    def loan_count(date = Date.today)
      query_as_hash(%Q{
          SELECT b.id,COUNT(*) 
          FROM loans l, clients cl, centers c, branches b
          WHERE l.client_id = cl.id AND cl.center_id = c.id AND c.branch_id = b.id AND l.disbursal_date <='#{date.strftime('%Y-%m-%d')}' AND l.deleted_at is NULL
          GROUP BY b.id})
    end

    def active_client_count(date = Date.today)      
      ids = repository.adapter.query(%Q{
                  SELECT loan_id, max(date) date
                  FROM loan_history 
                  WHERE date < '#{date.strftime('%Y-%m-%d')}' AND status in (5,6,7,8,9)
                  GROUP BY loan_id}).collect{|x| "(#{x.loan_id}, '#{x.date.strftime('%Y-%m-%d')}')"}.join(",")
      return false if ids.length==0     
      query_as_hash(%Q{
        SELECT branch_id, count(client_id)
        FROM loan_history lh
        WHERE (loan_id, date) in (#{ids}) AND status in (5,6)
        GROUP BY branch_id
      })
    end

    def dormant_client_count(date = Date.today)
      client_count(date) - active_client_count(date)
    end

    def client_count_by_loan_cycle(loan_cycle, date=Date.today)
      # this simply counts the number of loans for a given client without taking into account the status of those loans.
      query_as_hash(%Q{
            SELECT branch_id, COUNT(client_id) 
            FROM (
               SELECT client_id, count(*) AS num_loans, branch_id, center_id 
               FROM (
                  SELECT loan_id, client_id, center_id, branch_id,date, status,concat(client_id,'_',status) 
                  FROM loan_history 
                  WHERE (loan_id, date) IN (
                      #{get_latest_loan_history_row_before(date).map{|lh| "(#{lh.loan_id}, '#{lh.date.strftime('%Y-%m-%d')}')"}.join(",")}
                  )
                  GROUP BY CONCAT(client_id,'_',status)) AS dt1 
               GROUP BY client_id
               HAVING num_loans = #{loan_cycle}) 
               AS dt2 
               GROUP BY branch_id})
    end

    def clients_added_between_such_and_such_date_count(start_date, end_date)
      start_date = Date.parse(start_date) unless start_date.is_a? Date
      end_date = Date.parse(end_date) unless end_date.is_a? Date
      query_as_hash(%Q{
        SELECT b.id, COUNT(c.id) 
        FROM clients c, centers ce, branches b
        WHERE date_joined BETWEEN '#{start_date.strftime('%Y-%m-%d')}' AND '#{end_date.strftime('%Y-%m-%d')}'
        AND c.center_id = ce.id AND ce.branch_id = b.id
        GROUP BY b.id})
    end

    def clients_deleted_between_such_and_such_date_count(start_date, end_date)
      start_date = Date.parse(start_date) unless start_date.is_a? Date
      end_date = Date.parse(end_date) unless end_date.is_a? Date
      query_as_hash(%Q{
        SELECT b.id, COUNT(c.id) 
        FROM clients c, centers ce, branches b
        WHERE deleted_at BETWEEN '#{start_date.strftime('%Y-%m-%d')}' AND '#{end_date.strftime('%Y-%m-%d')}'
              AND c.center_id = ce.id AND ce.branch_id = b.id
        GROUP BY b.id})
    end

    def loans_repaid_between_such_and_such_date(start_date, end_date, what)
      start_date = Date.parse(start_date) unless start_date.is_a? Date
      end_date = Date.parse(end_date) unless end_date.is_a? Date
      return unless what.downcase == "sum" or what.downcase == "count"
      query_as_hash(%Q{
         SELECT lh.branch_id, #{what}(l.amount)
         FROM loans l, loan_history lh
         WHERE l.id = lh.loan_id 
               AND  lh.status = #{STATUSES.index(:repaid) + 1}  AND lh.date BETWEEN '#{start_date.strftime('%Y-%m-%d')}' AND '#{end_date.strftime('%Y-%m-%d')}'
         GROUP BY lh.branch_id})
    end

    def loans_disbursed_between_such_and_such_date(start_date, end_date, what)
      start_date = Date.parse(start_date) unless start_date.is_a? Date
      end_date = Date.parse(end_date) unless end_date.is_a? Date
      return unless what.downcase == "sum" or what.downcase == "count"
        query_as_hash(%Q{
         SELECT lh.branch_id, #{what}(l.amount)
         FROM loans l, loan_history lh
         WHERE l.id = lh.loan_id 
               AND  lh.status = #{STATUSES.index(:disbursed) + 1} AND  l.disbursal_date BETWEEN '#{start_date.strftime('%Y-%m-%d')}' AND '#{end_date.strftime('%Y-%m-%d')}'
         GROUP BY lh.branch_id})
    end

    [:principal, :interest].each do |payment_type|
      [:due, :received].each do |query_type|
        key = query_type==:received ? 'paid' : 'due'
        col_key = "#{payment_type}_#{key}".to_sym
        define_method("#{payment_type}_#{query_type}_between_such_and_such_date") do |start_date, end_date|
          LoanHistory.all(:date.gte => start_date, :date.lte => end_date).aggregate(:branch_id, col_key.send(:sum)).to_hash
        end
      end
    end

    def principal_outstanding(date = Date.today)
      date = Date.parse(date) unless date.is_a? Date
      get_latest_before(:actual_outstanding_principal, date)
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

    def center_managers(date)
      query_as_hash("select branch_id, count(distinct(manager_staff_id)) from centers group by branch_id ;")
    end

    def avg_outstanding_balance
      query_as_hash("select branch_id, avg(actual_outstanding_principal) from loan_history where current = true group by branch_id;")
    end

    def overdue_by(min, max)
      repository.adapter.query("SELECT branch_id, SUM(amount_in_default) FROM loan_history WHERE current = true AND days_overdue BETWEEN #{min} and #{max} GROUP BY branch_id").map {|x| [x[0],x[1].to_f]}.to_hash
    end

    def get_latest_loan_history_row_before(date = Date.today)
      date = Date.parse(date) unless date.is_a? Date
      repository.adapter.query("select loan_id, max(date) date from loan_history where date < '#{date.strftime('%Y-%m-%d')}' group by loan_id")
    end

    def get_latest_before(column, date = Date.today, group_by = nil)
      date = Date.parse(date) unless date.is_a? Date
      condition = get_latest_loan_history_row_before(date).map{|lh| "(#{lh.loan_id}, '#{lh.date.strftime('%Y-%m-%d')}')"}.join(",")
      sql = %Q{ SELECT branch_id, SUM(#{column.to_s}) as #{column} FROM loan_history WHERE (loan_id, date) IN (#{condition}) GROUP BY branch_id}
      query_as_hash(sql)
    end

    def method_missing(name, params)
      if /avg_([a-zA-Z0-9_]+)_per_([a-zA-Z0-9_]+)/.match(name.to_s)
        num = params ? send($1, *params[0]) : send($1)
        den = params ? send($2, *params[1]) : send($2)
        return num/den
      else
        raise NoMethodError
      end
    end
  end
end
