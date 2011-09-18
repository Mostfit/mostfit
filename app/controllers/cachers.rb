class Cachers < Application

  before :parse_date

  def index
    @cachers = get_cachers
    display [@cachers]
  end
  
  def generate
    BranchCache.update(@date)
    redirect resource(:cachers, :date => @date)
  end
  
  def update
    debugger
    @cachers = get_cachers
    stale_centers = @cachers.get_stale(:center)
    missing_centers = @cachers.get_missing_centers
    stale_center_branches = stale_centers.blank? ? [] : Center.all(:id => stale_centers.values.flatten).branches.aggregate(:id)
    missing_center_branches = missing_centers.blank? ? [] : missing_centers.keys
    bids =  (stale_center_branches + missing_center_branches).uniq
    bids.each{|bid| BranchCache.update(bid, @date)}
    
  end

  private
  
  def parse_date
    @date = params[:date] ? (params[:date].is_a?(Hash) ? Date.new(params[:date][:year].to_i, params[:date][:month].to_i, params[:date][:day].to_i) : Date.parse(params[:date])) : Date.today
  end

  def get_cachers
    q = {}
    q[:branch_id] = params[:branch_id] unless params[:branch_id].blank? 
    if (not params[:branch_id].blank?)
      q[:center_id] = params[:center_id] unless (params[:center_id].blank? or params[:center_id].to_i == 0)
    else
      q[:model_name] = "Branch"
    end
    q[:date] = @date
    Cacher.all(q)
  end
end
