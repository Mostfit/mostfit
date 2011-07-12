class Maintainer::Billing < Maintainer::Application

  def index
    render :layout => false
  end

  def get
    metric = params[:metric]
    dom = params[:day_of_month].to_i
    today = Date.today
    date_this_month = Date.new(today.year, today.month, dom)
    @data = []
    data_length = 30

    @data << get_stats(metric, date_this_month) if dom < today.mday
    (1..(data_length-@data.length)).each do |i|
      date = date_this_month << i
      @data << get_stats(metric, date)
    end

    (request.xhr?) ? (return @data.to_json) : (render :layout => false)
    # render :layout => false
  end

  private
  def get_stats(metric, date)
    case metric
    when "active_loans"
      count = repository.adapter.query(%Q{
        SELECT COUNT(date) FROM loan_history lh, (SELECt max(date) AS mdt, loan_id FROM loan_history lh2 WHERE date <= '#{date.strftime}' GROUP BY loan_id) AS md WHERE lh.date = md.mdt AND lh.loan_id = md.loan_id AND lh.status IN (2,4,5,6);
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
