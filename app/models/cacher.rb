class Cacher
  # like LoanHistory but for anything that has loans
  include DataMapper::Resource
  property :id,                              Serial
  property :type,                            Discriminator
  property :date,                            Date, :nullable => false, :index => true
  property :model_name,                      String, :nullable => false, :index => true
  property :model_id,                        Integer, :nullable => false, :index => true, :unique => [:model_name, :date]
  property :branch_id,                       Integer, :index => true
  property :center_id,                       Integer, :index => true
  property :funding_line_id,                 Integer, :index => true
  property :scheduled_outstanding_total,     Float, :nullable => false, :index => true
  property :scheduled_outstanding_principal, Float, :nullable => false, :index => true
  property :actual_outstanding_total,        Float, :nullable => false, :index => true
  property :actual_outstanding_principal,    Float, :nullable => false, :index => true
  property :scheduled_principal_due,         Float, :nullable => false, :index => true
  property :scheduled_interest_due,          Float, :nullable => false, :index => true
  property :principal_due,                   Float, :nullable => false, :index => true
  property :interest_due,                    Float, :nullable => false, :index => true
  property :principal_paid,                  Float, :nullable => false, :index => true
  property :interest_paid,                   Float, :nullable => false, :index => true
  property :total_principal_due,             Float, :nullable => false, :index => true
  property :total_interest_due,              Float, :nullable => false, :index => true
  property :total_principal_paid,            Float, :nullable => false, :index => true
  property :total_interest_paid,             Float, :nullable => false, :index => true
  property :advance_principal_paid,          Float, :nullable => false, :index => true
  property :advance_interest_paid,           Float, :nullable => false, :index => true
  property :advance_principal_adjusted,      Float, :nullable => false, :index => true
  property :advance_interest_adjusted,       Float, :nullable => false, :index => true
  property :principal_in_default,            Float, :nullable => false, :index => true
  property :interest_in_default,             Float, :nullable => false, :index => true
  property :total_fees_due,                  Float, :nullable => false, :index => true
  property :total_fees_paid,                 Float, :nullable => false, :index => true
  property :fees_due_today,                  Float, :nullable => false, :index => true
  property :fees_paid_today,                 Float, :nullable => false, :index => true

  property :created_at,                      DateTime
  property :updated_at,                      DateTime

  property :stale,                           Boolean, :default => false

  # TODO for the moment we are writing very stupid kind of caching.
  # what we should perhaps do is give caches the ability to generate themselves and to roll up into their parents
  # typically we will cache based on center, staff member and funding line and roll up to aggregate at branch level
  # for this we can do the following
  # create subclasses called CentreCache, StaffMemberCache, and FundingLineCache. 
  # Then create caches called BranchCenterCache, BranchStaffMemberCache and BranchFundingLineCache which roll up the balances


  def self.stale
    self.all(:stale => true)
  end

  def self.stalify_centers
    self.stale_centers.each do |date, centers|
      Cacher.transaction do |t|
        Cacher.all(:model_name => "Center", :model_id => centers, :date.gte => date, :stale => false).update(:stale => true)
      end
    end
  end
    
  def self.freshen
  end

  def self.stale_branches
    # firsts stalifies the centers and then finds the minimum date per branch for all stale centers
    self.stalify_centers
    Cacher.stale.aggregate(:branch_id, :date.min)
  end

  def self.stalify_branches
    Cacher.stale_branches.each do |branch_id, date|
      Cacher.all(:model_name => "Branch", :model_id => branch_id, :date.gte => date).update(:stale => true)
    end
  end

  def self.freshen_branches
    Cacher.all(:model_name => "Branch", :stale => true).each do |cache|
      BranchCache.update(cache.branch_id, cache.date)
    end
  end

  def self.stale_centers
    debugger
    cacher_update_times = self.all(:model_name => "Center").aggregate(:model_id, :updated_at.max)
    last_updated_at = cacher_update_times.map{|x| x[1]}.min
    payments_after_last_update = Payment.all(:created_at.gt => last_updated_at)
    centers_with_last_payment = payments_after_last_update.aggregate(:center_id, :received_on).map{|x| [x[0],[x[1]]]}
    # [[:center_id, :relevant_date]...]
    loans_after_last_update = Loan.all(:updated_at.gt => last_updated_at)
    centers_with_updated_loans = loans_after_last_update.aggregate(:c_center_id, :applied_on).map{|x| [x[0],[x[1]]]}
    # [[:center_id, :relevant_date]...]
    centers_to_update = (centers_with_last_payment.to_hash + centers_with_updated_loans.to_hash).map{|k,v| [k,v.is_a?(Array) ? v.min : v]}
    # now we have the centers, we can do the branches as well
    sc_by_date = centers_to_update.group_by{|x| x[1]}
    stale_centers = sc_by_date.map{|d, vs| [d,vs.map{|v| v[0]}]}.to_hash
  end

  def self.create(hash = {})
    # creates a cacher for any arbitrary condition. Also does grouping
    debugger
    date = hash.delete(:date) || Date.today
    group_by = hash.delete(:group_by) || []
    cols = hash.delete(:cols) ||  [:scheduled_outstanding_principal, :scheduled_outstanding_total, :actual_outstanding_principal, :actual_outstanding_total, 
                                    :total_interest_due, :total_interest_paid, :total_principal_due, :total_principal_paid, 
                                   :principal_in_default, :interest_in_default, :total_fees_due, :total_fees_paid]
    flow_cols = [:principal_due, :principal_paid, :interest_due, :interest_paid,
                 :scheduled_principal_due, :scheduled_interest_due, :advance_principal_adjusted, :advance_interest_adjusted,
                 :advance_principal_paid, :advance_interest_paid, :fees_due_today, :fees_paid_today]
    balances = LoanHistory.latest_sum(hash,date, group_by, cols)
    pmts = LoanHistory.composite_key_sum(LoanHistory.all(hash.merge(:date => date)).aggregate(:composite_key), group_by, flow_cols)
    # if there are no loan history rows that match today, then pmts is just a single hash, else it is a hash of hashes
    ng = flow_cols.map{|c| [c,0]}.to_hash
    balances.map{|k,v| [k,(pmts[k] || ng).merge(v)]}.to_hash 
  end



  def self.bulk_update_caches(set,where)
    #  not working
    Cacher.all(where).update(set)
  end

  def self.lock_caches(hash = {})
    #  not working
  end    

end

class BranchCache < Cacher
  def self.update(branch_id, date = Date.today)
    # updates the cache object for a branch
    # first create caches for the centers that do not have them
    debugger
    cached_centers = CenterCache.all(:model_name => "Center", :branch_id => branch_id, :date => date, :center_id.gt => 0, :stale => false).aggregate(:center_id)
    branch_centers = Branch.get(branch_id).centers.aggregate(:id)
    cids = (branch_centers - cached_centers)
    CenterCache.update(:center_id => cids, :date => date) unless cids.blank?

    # then add up all the cached centers
    branch_data = CenterCache.all(:model_name => "Center", :branch_id => branch_id, :date => date).map{|c| c.attributes.select{|k,v| v.is_a? Numeric}.to_hash}.reduce({}){|s,h| s+h}

    # TODO then add the loans that do not belong to any center
    # this does not exist right now so there is no code here.
    # when you add clients directly to the branch, do also update the code here

    bc = BranchCache.first_or_new({:model_name => "Branch", :model_id => branch_id, :date => date})
    attrs = branch_data.merge(:branch_id => branch_id, :center_id => 0, :model_id => branch_id, :stale => false)
    if bc.new?
      bc.attributes = attrs.merge(:id => nil)
      bc.save
    else
      bc.update(attrs.merge(:id => bc.id))
    end
  end

  def self.missing(branch_ids = nil, hash = {})
    debugger
    hash = hash.merge(:branch_id => branch_ids) if branch_ids
    history_dates = LoanHistory.all(hash).aggregate(:branch_id, :date).group_by{|x| x[0]}.map{|k,v| [k,v.map{|x| x[1]}]}.to_hash
    cache_dates = BranchCache.all(hash).aggregate(:branch_id, :date).group_by{|x| x[0]}.map{|k,v| [k,v.map{|x| x[1]}]}.to_hash
    # hopefully we now have {:branch_id => :dates}
    missing_dates = history_dates - cache_dates
  end
  
  def self.missing_for_date(date = Date.today, branch_ids = nil, hash = {})
    BranchCache.missing(branch_ids, hash.merge(:date => date))
  end

  def self.stale_for_date(date = Date.today, branch_ids = nil, hash = {})
  end
end

class CenterCache < Cacher

  def self.update(hash = {})
    # creates a cache per center for branches and centers per the hash passed as argument
    date = hash.delete(:date) || Date.today
    hash = hash.select{|k,v| [:branch_id, :center_id].include?(k)}.to_hash
    centers_data = CenterCache.create(hash.merge(:date => date, :group_by => [:branch_id,:center_id])).deepen.values.sum
    now = DateTime.now
    centers_data.delete(:no_group)
    cs = centers_data.keys.flatten.map do |center_id|
      # cc = CenterCache.first_or_new({:model_name => "Center", :model_id => center_id, :date => date})
      # centers_data[center_id].each{|k,v| cc.send("#{k}=".to_sym, v) if cc.respond_to?(k)}
      # cc.stale = false
      # cc
      centers_data[center_id].merge({:type => "CenterCache",:model_name => "Center", :model_id => center_id, :date => date, :updated_at => now})
    end
    debugger
    sql = get_bulk_insert_sql("cachers", cs)
    CenterCache.all(:date => date, :id => centers_data.keys).destroy!
    repository.adapter.execute(sql)
  end

end
