class Cachers < Application

  before :parse_date

  def index
    q = {}
    q[:branch_id] = params[:branch_id] unless params[:branch_id].blank? 
    if (not params[:branch_id].blank?)
      q[:center_id] = params[:center_id] unless (params[:center_id].blank? or params[:center_id].to_i == 0)
    else
      q[:model_name] = "Branch"
    end
    q[:date] = @date
    @cachers = Cacher.all(q)
    display [@cachers]
  end
  
  def generate
    BranchCache.missing_for_date(@date).keys.each do |b|
      BranchCache.update(b, @date)
    end
    redirect resource(:cachers, :date => @date)
  end
  
  def update
    debugger
    bids = BranchCache.all(:date => @date).get_stale
    bids.each{|bid| BranchCache.update(bid, @date)}
    
  end

  private
  
  def parse_date
    @date = params[:date] ? (params[:date].is_a?(Hash) ? Date.new(params[:date][:year].to_i, params[:date][:month].to_i, params[:date][:day].to_i) : Date.parse(params[:date])) : Date.today
  end

end
