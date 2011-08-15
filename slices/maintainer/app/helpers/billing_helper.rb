module Merb::Maintainer::BillingHelper

  def get_stats(metric, dom)
    today = Date.today
    date_this_month = Date.new(today.year, today.month, dom)
    data = []
    data_length = 30

    data << get_stat(metric, date_this_month) if dom < today.mday
    (1..(data_length-data.length)).each do |i|
      date = date_this_month << i
      data << get_stat(metric, date)
    end
    data
  end

  # to add a new metric to the billing section, add a case below
  def get_stat(metric, date)
    case metric
    when "active_loans"
      count = repository.adapter.query(%Q{
        SELECT COUNT(date) FROM loan_history lh,
        (SELECT max(date) AS mdt, loan_id FROM loan_history lh2 WHERE date <= '#{date.strftime}' GROUP BY loan_id) AS md
        WHERE lh.date = md.mdt AND lh.loan_id = md.loan_id AND lh.status IN (2,4,5,6);
      }).first
    when "total_loans"
      count = Loan.count(:applied_on.lte => date)
    when "total_clients"
      count = Client.count(:date_joined.lte => date)
    end
    {
      :date => date.strftime(DATE_FORMAT_READABLE),
      :count => count
    }
  end

end
