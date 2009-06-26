module Reporting

  module Branch

    def member_ids
      repository.adapter.query(%Q{
          SELECT cl.id 
          FROM clients cl, centers c, branches b
          WHERE cl.center_id = c.id AND c.branch_id = b.id})
    end

    def client_count
      repository.adapter.query(%Q{
          SELECT b.id, COUNT(cl.id)
          FROM clients cl, centers c, branches b
          WHERE cl.center_id = c.id AND c.branch_id = b.id
          GROUP BY b.id})            
    end

    def loan_count
      repository.adapter.query(%Q{
          SELECT COUNT(*) 
          FROM loans l, clients cl, centers c, branches b
          WHERE l.client_id = cl.id AND cl.center_id = c.id AND c.branch_id = b.id
          GROUP BY b.id})            
    end

    def active_client_count
      debugger
      repository.adapter.query(%Q{
         SELECT branch_id, COUNT(DISTINCT client_id)
         FROM loan_history lh
         WHERE current = true AND lh.status <= 3
         GROUP BY branch_id})
    end

    def dormant_client_count
      debugger
      active = active_client_count
      total = client_count
      dormant = []
      active.each_with_index do |v,i|
        dormant << [v[0],total[i][1] - v[1]]
      end
      dormant
    end

    def client_count_by_loan_cycle(loan_cycle)
      # a person is deemed to be in a loan_cycle if the number of repaid / written off loans he has is 
      # 1) equal to loan_cycle - 1 if he has a loan outstanding or
      # but ONLY IF loan_cycle > 1
      #
      # TODO
      # We can optimise this per model (i.e. branch) by returning one hash like {1 => 2436, 2 => 4367} etc
      if loan_cycle == 1
        client_ids = repository.adapter.query(" select count(client_id),branch_id from (select count(client_id) as x, client_id, status, branch_id from loan_history where current = true group by client_id having x = 1) as dt where dt.status <= 3 group by branch_id")
      else
        # first find the Clients with repaid/written_off loans numbering loan_cycle - 1 and with loan outstanding
        client_ids = repository.adapter.query(%Q{
         SELECT COUNT(loan_id),client_id,branch_id
         FROM loan_history lh
         WHERE current = true AND lh.status <= 3 and client_id in (
             SELECT id FROM 
               (SELECT COUNT(loan_id), client_id as id 
                FROM loan_history lh 
                WHERE current = true AND lh.status > 3 
                GROUP BY client_id 
                HAVING COUNT(loan_id) = #{loan_cycle - 1})  # this doesn't work for loan cycle one.
                AS dt) 
             GROUP BY client_id HAVING COUNT(loan_id) > 0})
      end
    end

    def clients_added_between_such_and_such_date_count(start_date, end_date)
      start_date = Date.parse(start_date) unless start_date.is_a? Date
      end_date = Date.parse(end_date) unless end_date.is_a? Date
      repository.adapter.query(%Q{
        SELECT b.id, COUNT(c.id) 
        FROM clients c, centers ce, branches b
        WHERE date_joined BETWEEN '#{start_date}' AND '#{end_date}'
              AND c.center_id = ce.id AND ce.branch_id = b.id
        GROUP BY b.id})
    end

    def clients_deleted_between_such_and_such_date_count(start_date, end_date)
      start_date = Date.parse(start_date) unless start_date.is_a? Date
      end_date = Date.parse(end_date) unless end_date.is_a? Date
      repository.adapter.query(%Q{
        SELECT b.id, COUNT(c.id) 
        FROM clients c, centers ce, branches b
        WHERE deleted_at BETWEEN '#{start_date}' AND '#{end_date}'
              AND c.center_id = ce.id AND ce.branch_id = b.id
        GROUP BY b.id})
    end

    def loans_repaid_between_such_and_such_date(start_date, end_date, what)
      start_date = Date.parse(start_date) unless start_date.is_a? Date
      end_date = Date.parse(end_date) unless end_date.is_a? Date
      return unless what.downcase == "sum" or "count"
        repository.adapter.query(%Q{
         SELECT #{what}(l.amount), lh.branch_id 
         FROM loans l, loan_history lh
         WHERE l.id = lh.loan_id 
               AND  lh.status = 4 AND lh.date BETWEEN #{start_date} AND #{end_date}
         GROUP BY lh.branch_id})
    end

    def principal_received_between_such_and_such_date(start_date, end_date)
      start_date = Date.parse(start_date) unless start_date.is_a? Date
      end_date = Date.parse(end_date) unless end_date.is_a? Date
      repository.adapter.query(%Q{ select sum(principal), b.id from payments p, loans l, clients cl, centers c, branches b where p.received_on between '#{start_date}' and '#{end_date}' and p.loan_id = l.id and l.client_id = cl.id and cl.center_id = c.id and c.branch_id = b.id  group by b.id})
    end

    def interest_received_between_such_and_such_date(start_date, end_date)
      start_date = Date.parse(start_date) unless start_date.is_a? Date
      end_date = Date.parse(end_date) unless end_date.is_a? Date
      repository.adapter.query(%Q{ select sum(interest), b.id from payments p, loans l, clients cl, centers c, branches b where p.received_on between '#{start_date}' and '#{end_date}' and p.loan_id = l.id and l.client_id = cl.id and cl.center_id = c.id and c.branch_id = b.id  group by b.id})
    end

    def current_principal_outstanding


  end
end
