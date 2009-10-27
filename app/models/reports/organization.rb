module Reporting
  module OrganizationReports
    def query_as_number(sql)
      repository.adapter.query(sql)[0]
    end

    def branch_count(end_date)
      query_as_number(%Q{
          SELECT COUNT(b.id) as count
          FROM branches b
          WHERE  b.created_at < '#{end_date}'})
    end

    def centers_count(end_date)
      query_as_number(%Q{
          SELECT COUNT(c.id) as count
          FROM centers c
          WHERE  c.created_at < '#{end_date}'})
    end

    def cms_count(end_date)
      query_as_number(%Q{
          SELECT COUNT(DISTINCT(c.manager_staff_id)) as count
          FROM centers c
          WHERE  c.created_at < '#{end_date}'})
    end

    def clients_count(end_date)
      query_as_number(%Q{
          SELECT COUNT(*) as count
          FROM clients c
          WHERE c.date_joined < '#{end_date}'})
    end

    def borrowers(end_date)
      query_as_number(%Q{
         SELECT COUNT(DISTINCT client_id)
         FROM loan_history lh
         WHERE lh.status <= 3 AND lh.created_at<'#{end_date}'})
    end

    def disbursed(end_date, what)
      end_date = Date.parse(end_date) unless end_date.is_a? Date
      return unless what.downcase == "sum" or what.downcase == "count"
        query_as_number(%Q{
         SELECT #{what}(l.amount)
         FROM loans l
         WHERE l.disbursal_date < '#{end_date}'
        })
    end

    def net_portfolio(end_date)
      repository.adapter.query(%Q{
        SELECT min(actual_outstanding_total) tot
        FROM loan_history where status=3 and date BETWEEN '#{start_date}' AND '#{end_date}'
        GROUP BY loan_id
        ORDER BY loan_id, date DESC}).reduce{|sum, x| sum+x}
    end
  end
end
