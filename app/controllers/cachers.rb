class Cachers < Application

  before :parse_dates

  def index
    @date ||= Date.today
    @from_date = @to_date = @date
    get_cachers
    @keys = [:date] + @keys
    display @cachers
  end

  def missing
    params[:stale] = true
    get_cachers
    display @cachers, :template => 'cachers/index'
  end
  
  def generate
    if @from_date and @to_date
      (@from_date..@to_date).each{|date| BranchCache.update(date)}
    else
      BranchCache.update(@date || Date.today)
    end
    redirect request.referer
  end
  
  def update
    BranchCache.update(@date)
    redirect resource(:cachers, :date => @date)
  end

  # puts stale branch caches in a queue for recalculation
  def freshen
  end

  def consolidate
    get_cachers
    group_by = @level.to_s.singularize
    group_by_model = Kernel.const_get(group_by.camelcase) 
    unless group_by == "loan"
      @cachers = @cachers.group_by{|c| c.send("#{group_by}_id".to_sym)}.to_hash.map do |group_by_id, cachers| 
        cachers.reduce(:consolidate)
      end
    end
    display @cachers, :template => 'cachers/index'
  end

  def split
    get_cachers
    @cachers =  @center ? @cachers.all(:center_id => @center.id) : @cachers.all(:center_id => 0)
    display @cachers, :template => 'cachers/index'
  end

  # recalculates loan history and regenerates the cache for a center
  #
  # params => {:center_id => x}
  def rebuild
    @center = Center.get(params[:center_id])
    raise NotFound unless @center
    CenterCache.stalify(:center_id => params[:center_id], :date => (@date || @center.creation_date))
    @center.loans.each{|l| l.update_history}
    BranchCache.update(@date, @center.branch.id)
    redirect request.referer, :message => {:notice => 'Rebuilt caches for today. Marked caches after today as stale. They will be rebuilt upon request'}
  end

  private
  
  def parse_dates
    {:date => Date.today, :from_date => Date.today - 7, :to_date => Date.today}.each do |date, default|
      instance_variable_set("@#{date.to_s}", (params[date] ? (params[date].is_a?(Hash) ? Date.new(params[date][:year].to_i, params[date][:month].to_i, params[date][:day].to_i) : Date.parse(params[date])) : nil))
    end
    @date = @to_date unless @date
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
    q[:stale] = true if params[:stale]
    @cachers = Cacher.all(q)
    q.delete(:model_name)
    @missing_centers = CenterCache.missing(q)
    get_context
  end

  def get_context
    @center = params[:center_id].blank? ? nil : Center.get(params[:center_id])
    @branch = params[:branch_id].blank? ? nil : Branch.get(params[:branch_id])
    @center_names = @cachers.blank? ? {} : Center.all(:id => @cachers.aggregate(:center_id)).aggregate(:id, :name).to_hash
    @branch_names = @cachers.blank? ? {} : Branch.all(:id => @cachers.aggregate(:branch_id)).aggregate(:id, :name).to_hash
    q = (@from_date and @to_date) ? {:date => @from_date..@to_date} : {:date => @date}
    @stale_centers = CenterCache.all(q.merge(:stale => true))
    @stale_branches = BranchCache.all(q.merge(:stale => true))
    @last_cache_update = @cachers.aggregate(:updated_at.min)
    @resource = params[:action] == "index" ? :cachers : (params[:action].to_s + "_" + "cachers").to_sym
    @keys = [:branch_id, :center_id] + ReportFormat.get(params[:report_format] || 1).keys 
    @total_keys = @keys[3..-1]
    if @resource == :split_cachers
      @level = params[:center_id].blank? ? :branches : :centers
      @keys = [:date] + @keys
    else 
      @level = (not params[:center_id].blank?) ? :loans : ((not params[:branch_id].blank?) ? :centers : :branches)
    end
  end

end
