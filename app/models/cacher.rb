class Cacher
  # like LoanHistory but for anything that has loans
  include DataMapper::Resource
  property :id,                              Serial
  property :date,                            Date, :nullable => false, :index => true
  property :model_name,                      String, :nullable => false, :index => true
  property :model_id,                        Integer, :nullable => false, :index => true, :unique => [:model_name, :date]
  property :branch_id,                       Integer, :index => true
  property :center_id,                       Integer, :index => true
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


  def self.stalify
    stale_branches = Center.all(:id => self.stale_centers.keys).aggregate(:branch_id)
  end
    
  def self.stale_items
    debugger
    cacher_update_times = self.all(:model_name => "Center").aggregate(:model_id, :updated_at.max)
    last_updated_at = cacher_update_times.map{|x| x[1]}.min
    payments_after_last_update = Payment.all(:created_at.gt => last_updated_at)
    centers_with_last_payment = payments_after_last_update.aggregate(:center_id, :received_on)
    # [[:center_id, :relevant_date]...]
    loans_after_last_update = Loan.all(:updated_at.gt => last_updated_at)
    centers_with_updated_loans = loans_after_last_update.aggregate(:c_center_id, :applied_on)
    # [[:center_id, :relevant_date]...]
    centers_to_update = (centers_with_last_payment.to_hash + centers_with_updated_loans.to_hash).map{|k,v| [k,v.is_a?(Array) ? v.min : v]}
    # now we have the centers, we can do the branches as well
    sc_by_date = centers_to_update.group_by{|x| x[1]}
    stale_centers = sc_by_date.map{|d, vs| [d,vs.map{|v| v[0]}]}.to_hash
    stale_branches = stale_centers.map{|d, cs| [d, Center.all(:id => cs).aggregate(:branch_id)]}.to_hash
    {:branches => stale_branches, :centers => stale_centers}
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
    balances.map{|k,v| [k,(pmts[k] || ng).merge(v)]}.to_hash # v must be the arg to merge because pmts can have dodgy values
  end

  def self.update_branch_cache(branch_id, date = Date.today)
    # updates the cache object for a branch
    # first create caches for the centers that do not have them
    debugger
    cached_centers = Cacher.all(:model_name => "Center", :branch_id => branch_id, :date => date).aggregate(:center_id).select{|c| c > 0}
    branch_centers = Branch.get(branch_id).centers.aggregate(:id)
    cids = (branch_centers - cached_centers)
    Cacher.update_centers_cache(:center_id => cids, :date => date) unless cids.blank?

    # then add up all the cached centers
    branch_data = Cacher.all(:model_name => "Center", :branch_id => branch_id, :date => date).map{|c| c.attributes.select{|k,v| v.is_a? Numeric}.to_hash}.reduce({}){|s,h| s+h}

    # TODO then add the loans that do not belong to any center
    # this does not exist right now so there is no code here.
    # when you add clients directly to the branch, do also update the code here

    bc = Cacher.first_or_new({:model_name => "Branch", :model_id => branch_id, :date => date})
    attrs = branch_data.merge(:branch_id => branch_id, :center_id => 0, :model_id => branch_id)
    if bc.new?
      bc.attributes = attrs.merge(:id => nil)
      bc.save
    else
      bc.update_attributes(attrs)
    end
  end

  def self.update_centers_cache(hash = {})
    debugger
    date = hash.delete(:date) || Date.today
    hash = hash.select{|k,v| [:branch_id, :center_id].include?(k)}.to_hash
    # creates a cache per center for branches and centers per the hash passed as argument
    centers_data = Cacher.create(hash.merge(:date => date, :group_by => [:branch_id,:center_id])).deepen.values.sum
    cs = centers_data.keys.flatten.map do |center_id|
      cc = Cacher.first_or_new({:model_name => "Center", :model_id => center_id, :date => date})
      centers_data[center_id].each{|k,v| cc.send("#{k}=".to_sym, v) if cc.respond_to?(k)}
      cc
    end
    Cacher.transaction do |t|
      r = cs.map{|c| [c,c.save]}
      if r.map{|x| x[1]}.include?(false)
        debugger
        t.rollback
      end
    end
     
  end


  def self.bulk_update_caches(set,where)
    #  not working
    Cacher.all(where).update(set)
  end

  def self.lock_caches(hash = {})
    #  not working
  end    




end

