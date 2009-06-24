module Reporting

  module Branch

    def member_ids
      repository.adapter.query(%Q{
          SELECT cl.id 
          FROM clients cl, centers c, branches b
          WHERE cl.center_id = c.id AND c.branch_id = b.id})
    end

    def member_count
      repository.adapter.query(%Q{
          SELECT COUNT(*) 
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

    def active_clients
      repository.adapter.query(%Q{
         SELECT client_id,branch_id
         FROM loan_history lh
         WHERE current = true AND lh.status <= 3})
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
      repository.adapter.query(%Q{
        SELECT COUNT(DISTINCT client), branch FROM
        (SELECT cl.id AS client, b.id AS branch FROM clients cl, centers c, branches b 
        WHERE cl.center_id = c.id AND c.branch_id = b.id AND cl.id NOT IN
          (SELECT client_id FROM 
             (SELECT COUNT(loan_id), client_id 
              FROM loan_history 
              WHERE current = true AND status <= 3 
              GROUP BY client_id) AS dt) ) AS dt2 GROUP BY branch})
    end
  end
end
