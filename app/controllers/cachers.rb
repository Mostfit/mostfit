class Cachers < Application

  def index
    q = {}
    @date = params[:date] ? (params[:date].is_a?(Hash) ? Date.new(params[:date][:year].to_i, params[:date][:month].to_i, params[:date][:day].to_i) : Date.parse(params[:date])) : Date.today
    q[:branch_id] = params[:branch_id] unless params[:branch_id].blank? 
    if (not params[:branch_id].blank?)
      q[:center_id] = params[:center_id] unless params[:center_id].blank?
    else
      q[:center_id] = 0
    end
    q[:date] = @date
    @cachers = Cacher.all(q)
    display [@cachers]
  end
  
end
