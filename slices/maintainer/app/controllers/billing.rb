class Maintainer::Billing < Maintainer::Application

  def index
    render :layout => false
  end

  def get
    metric = params[:metric]
    dom = params[:day_of_month].to_i
    @data = get_stats(metric, dom)
    (request.xhr?) ? (return @data.to_json) : (render :layout => false)
  end

end
