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

  def consolidate
    debugger
    @cachers = get_cachers
    @stale = @cachers.stale.aggregate(:branch_id, :center_id)
    @center_names = @cachers.blank? ? {} : Center.all(:id => @cachers.aggregate(:center_id)).aggregate(:id, :name).to_hash
    @branch_names = @cachers.blank? ? {} : Branch.all(:id => @cachers.aggregate(:branch_id)).aggregate(:id, :name).to_hash
    @last_cache_update = @cachers.aggregate(:updated_at.min)
    group_by = params[:group_by] ||= "branch"
    group_by_model = Kernel.const_get(group_by.camelcase) 
    @grouped_cachers = @cachers.group_by{|c| c.send("#{group_by}_id".to_sym)}.to_hash.map do |group_by_id, cachers| 
      group_obj = group_by_model.get(group_by_id)
      [group_obj, cachers.reduce(:consolidate)]
    end
    display @cachers
  end

  private
  
  def parse_dates
    {:date => Date.today, :from_date => Date.today - 7, :to_date => Date.today}.each do |date, default|
      instance_variable_set("@#{date.to_s}", (params[date] ? (params[date].is_a?(Hash) ? Date.new(params[date][:year].to_i, params[date][:month].to_i, params[date][:day].to_i) : Date.parse(params[date])) : Date.today))
    end
  end


  def get_cachers
    q = {}
    q[:branch_id] = params[:branch_id] unless params[:branch_id].blank? 
    if (not params[:branch_id].blank?)
      q[:center_id] = params[:center_id] unless (params[:center_id].blank? or params[:center_id].to_i == 0)
    else
      q[:model_name] = "Branch"
    end
    q[:date] = @date if @date
    q[:date] = @from_date..@to_date if (@from_date and @to_date)
    Cacher.all(q)
  end
end
