class Cachers < Application

  before :parse_dates

  def index
    @cachers = get_cachers
    display [@cachers], :layout => (params[:layout] or Nothing).to_sym
  end
  
  def generate
    BranchCache.update(@date)
    redirect resource(:cachers, :date => @date)
  end
  
  def update
    BranchCache.update(@date)
    redirect resource(:cachers, :date => @date)
  end

  private
  
  def parse_dates
    {:date => Date.today, :from_date => Date.today - 7, :to_date => Date.today}.each do |date, default|
      instance_variable_set("@#{date.to_s}", (params[date] ? (params[date].is_a?(Hash) ? Date.new(params[date][:year].to_i, params[date][:month].to_i, params[date][:day].to_i) : Date.parse(params[date])) : Date.today))
    end
  end

  def consolidate
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
