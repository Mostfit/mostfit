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

  COLS =   [:scheduled_outstanding_principal, :scheduled_outstanding_total, :actual_outstanding_principal, :actual_outstanding_total, 
                                    :total_interest_due, :total_interest_paid, :total_principal_due, :total_principal_paid, 
                                   :principal_in_default, :interest_in_default, :total_fees_due, :total_fees_paid]
  FLOW_COLS = [:principal_due, :principal_paid, :interest_due, :interest_paid,
                 :scheduled_principal_due, :scheduled_interest_due, :advance_principal_adjusted, :advance_interest_adjusted,
                 :advance_principal_paid, :advance_interest_paid, :fees_due_today, :fees_paid_today]


  # TODO for the moment we are writing very stupid kind of caching.
  # what we should perhaps do is give caches the ability to generate themselves and to roll up into their parents
  # typically we will cache based on center, staff member and funding line and roll up to aggregate at branch level
  # for this we can do the following
  # create subclasses called CentreCache, StaffMemberCache, and FundingLineCache. 
  # Then create caches called BranchCenterCache, BranchStaffMemberCache and BranchFundingLineCache which roll up the balances

  def self.stale
    self.all(:stale => true)
  end

  def self.get_stale(what)
    raise ArgumentError unless [:center, :branch].include?(what)
    # get the last update time per cacher as an array [[model_id, updated_at]...]
    cacher_update_times = self.all(:model_name => what.to_s.camel_case).aggregate(:model_id, :updated_at.max).to_hash
    model_ids = cacher_update_times.map{|x| x[0]}
    return {} if model_ids.empty?
    # get the absolutely lowest last update time
    last_updated_at = cacher_update_times.map{|x| x[1]}.min
    # get all payments after this time and return an array  [[model_id, created_at]....]
    models_with_payment_update = Payment.all(:created_at.gt => last_updated_at, "#{what}_id".to_sym => model_ids).aggregate("#{what}_id".to_sym, :created_at.max).to_hash
    # then check created_at.max against each cacher's updated_at
    models_with_payment_update = models_with_payment_update.select{|k,v| cacher_update_times[k] < v} 
    
    # then do the same for loan updates
    models_with_loan_update = Loan.all(:updated_at.gt => last_updated_at, "c_#{what}_id".to_sym => model_ids).aggregate("c_#{what}_id".to_sym, :updated_at.max)
    models_with_loan_update = models_with_loan_update.select{|k,v| cacher_update_times[k] < v} 
    # and then turn it into an hash of {:date1 => [:model_id1, model_id2]...}
    models_with_payment_update = models_with_payment_update.map{|x| {x[1] => [x[0]]}}.reduce({}){|s,h| s + h}
    models_with_loan_update = models_with_loan_update.map{|x| {x[1] => [x[0]]}}.reduce({}){|s,h| s + h}
    # and sum the two
    models_with_payment_update + models_with_loan_update
  end

  def self.create(hash = {})
    # creates a cacher from loan_history table for any arbitrary condition. Also does grouping
    date = hash.delete(:date) || Date.today
    group_by = hash.delete(:group_by) || []
    cols = hash.delete(:cols) || COLS
    flow_cols = FLOW_COLS
    balances = LoanHistory.latest_sum(hash,date, group_by, cols)
    pmts = LoanHistory.composite_key_sum(LoanHistory.all(hash.merge(:date => date)).aggregate(:composite_key), group_by, flow_cols)
    # if there are no loan history rows that match today, then pmts is just a single hash, else it is a hash of hashes
    ng = flow_cols.map{|c| [c,0]}.to_hash # ng = no good. we return this if we get dodgy data
    balances.map{|k,v| [k,(pmts[k] || ng).merge(v)]}.to_hash 
  end

  def consolidate (other)
    # this not addition, it is consolidation
    # for cols (i.e balances) it takes the last balance, and for flow_cols i.e. payments, it takes the sum and returns a new cacher
    # it is used for summing cachers across time
    raise ArgumentError "cannot add cacher to something that is not a cacher" unless other.is_a? Cacher
    raise ArgumentError "cannot add cachers of different classes" unless self.class == other.class
    attrs = (self.date > other.date ? self : other).attributes.dup
    me = self.attributes; other = other.attributes;
    attrs.delete(:id)
    FLOW_COLS.map{|col| attrs[col] = me[col] + other[col]}
    Cacher.new(attrs)
  end

  def + (other)
    # this adds all attributes and uses the latest date to add two cachers together
    raise ArgumentError "cannot add cacher to something that is not a cacher" unless other.is_a? Cacher
    raise ArgumentError "cannot add cachers of different classes" unless self.class == other.class
    date = (self.date > other.date ? self.date : other.date)
    me = self.attributes; other = other.attributes;
    attrs = me + other; attrs[:date] = date;
    Cacher.new(attrs)
  end    


end

class BranchCache < Cacher
  def self.update(branch_id = nil, date = Date.today)
    # updates the cache object for a branch
    # first create caches for the centers that do not have them
    debugger
    raise ArgumentError "multiple branches not supported for the moment" if branch_id.is_a? Array
    branch_ids = Branch.all.aggregate(:id) unless branch_ids
    ccs = Cacher.all(:model_name => "Center", :branch_id => branch_id, :date => date, :center_id.gt => 0)
    cached_centers = ccs.aggregate(:center_id)
    branch_centers = Branch.all(:id => branch_id).centers.aggregate(:id)
    stale_centers = ccs.get_stale(:center).values.flatten
    cids = (branch_centers - cached_centers) + stale_centers
    return true if cids.blank?
    return false unless (CenterCache.update(:center_id => cids, :date => date))

    # then add up all the cached centers
    branch_data = CenterCache.all(:model_name => "Center", :branch_id => branch_id, :date => date).map{|c| c.attributes.select{|k,v| v.is_a? Numeric}.to_hash}.reduce({}){|s,h| s+h}

    # TODO then add the loans that do not belong to any center
    # this does not exist right now so there is no code here.
    # when you add clients directly to the branch, do also update the code here

    bc = BranchCache.first_or_new({:model_name => "Branch", :model_id => branch_id, :date => date})
    attrs = branch_data.merge(:branch_id => branch_id, :center_id => 0, :model_id => branch_id, :stale => false, :updated_at => DateTime.now)
    if bc.new?
      bc.attributes = attrs.merge(:id => nil, :updated_at => DateTime.now)
      bc.save
    else
      bc.update(attrs.merge(:id => bc.id))
    end
  end

    

  def self.missing(branch_ids = nil, hash = {})
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
      debugger
      centers_data = CenterCache.create(hash.merge(:date => date, :group_by => [:branch_id,:center_id])).deepen.values.sum
      return false if centers_data == nil
      now = DateTime.now
      centers_data.delete(:no_group)
      return true if centers_data.empty?
      cs = centers_data.keys.flatten.map do |center_id|
        # cc = CenterCache.first_or_new({:model_name => "Center", :model_id => center_id, :date => date})
        # centers_data[center_id].each{|k,v| cc.send("#{k}=".to_sym, v) if cc.respond_to?(k)}
        # cc.stale = false
        # cc
        centers_data[center_id].merge({:type => "CenterCache",:model_name => "Center", :model_id => center_id, :date => date, :updated_at => now})
      end
      return false if cs.nil?
      sql = get_bulk_insert_sql("cachers", cs)
      raise unless CenterCache.all(:date => date, :id => centers_data.keys).destroy!
      repository.adapter.execute(sql)
  end

end
