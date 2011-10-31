# The base class for all aggregating caches.
# These caches can be made for anything that 'has' loans, like branches,
# centers, managers, fundlines, etc.  The cache reflects the state of the
# loans hanging under that particular object on a particulat date.

class LoanAggregatingCache
  include DataMapper::Resource
  property :id,                              Serial  # actually the composite key of (type/model_name, model_id, date)
  property :type,                            Discriminator
  property :date,                            Date, :nullable => false, :index => true
  property :model_name,                      String, :nullable => false, :index => true  # can we derive the model namde from the type (eg BranchCache) property?

  property :model_id,                        Integer, :nullable => false, :index => true, :unique => [:model_name, :date]  # i do not see this (unique with array) documented anywhere, sure this works?

  property :scheduled_outstanding_total,     Float, :nullable => false
  property :scheduled_outstanding_principal, Float, :nullable => false
  property :actual_outstanding_total,        Float, :nullable => false
  property :actual_outstanding_principal,    Float, :nullable => false
  property :scheduled_principal_due,         Float, :nullable => false
  property :scheduled_interest_due,          Float, :nullable => false
  property :principal_due,                   Float, :nullable => false
  property :interest_due,                    Float, :nullable => false
  property :principal_paid,                  Float, :nullable => false
  property :interest_paid,                   Float, :nullable => false
  property :total_principal_due,             Float, :nullable => false
  property :total_interest_due,              Float, :nullable => false
  property :total_principal_paid,            Float, :nullable => false
  property :total_interest_paid,             Float, :nullable => false
  property :advance_principal_paid,          Float, :nullable => false
  property :advance_interest_paid,           Float, :nullable => false
  property :advance_principal_adjusted,      Float, :nullable => false
  property :advance_interest_adjusted,       Float, :nullable => false
  property :principal_in_default,            Float, :nullable => false
  property :interest_in_default,             Float, :nullable => false
  property :total_fees_due,                  Float, :nullable => false
  property :total_fees_paid,                 Float, :nullable => false
  property :fees_due_today,                  Float, :nullable => false
  property :fees_paid_today,                 Float, :nullable => false

  property :created_at,                      DateTime
  property :updated_at,                      DateTime

  property :stale,                           Boolean, :default => false  # how does this exactly work?

  AGGR_BY_LAST = [:scheduled_outstanding_principal, :scheduled_outstanding_total,
                  :actual_outstanding_principal,    :actual_outstanding_total,
                  :total_interest_due,              :total_interest_paid,
                  :total_principal_due,             :total_principal_paid,
                  :principal_in_default,            :interest_in_default,
                  :total_fees_due,                  :total_fees_paid]

  AGGR_BY_SUM  = [:principal_due,              :principal_paid,
                  :interest_due,               :interest_paid,
                  :scheduled_principal_due,    :scheduled_interest_due,
                  :advance_principal_adjusted, :advance_interest_adjusted,
                  :advance_principal_paid,     :advance_interest_paid,
                  :fees_due_today,             :fees_paid_today]


  def self.get_missing_centers  # should be implemented on the CenterCache subclass, right?
    return [] if self.all.empty?
    branch_ids = self.aggregate(:branch_id)
    dates = self.aggregate(:date)
    branch_centers = Branch.all(:id => branch_ids).centers(:creation_date.lte => dates.min).aggregate(:branch_id, :id).group_by{|x| x[0]}.map{|k,v| [k, v.map{|x| x[1]}]}.to_hash
    cached_centers = Cacher.all(:model_name => "Center", :branch_id => branch_ids, :date => dates).aggregate(:branch_id, :center_id).group_by{|x| x[0]}.map{|k,v| [k, v.map{|x| x[1]}]}.to_hash
    branch_centers - cached_centers
  end


# it seems this method is not fully implemented yet...
  # lets make the argument signature clear

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

    # now to add approvals, disbursals, writeoffs, etc.  are available on sid's branch.
  end


# im quite sure this is not possible by sql..
# but lets try:
  # select sum(AGGR_BY_SUM), last(AGGR_BY_LAST) from cachers where date >= x and date <= y order by date asc grouped by type;
# if this works we can make a self.consolidate(ids_array)


  # Consolidates this cache with an other cache.
  # For cols (i.e balances) it takes the last balance, and for flow_cols i.e. payments, it takes the sum and returns a new cacher
  # it is used for summing cachers across time.
  def consolidate(other)
    return self if other.nil?
    raise ArgumentError "Cannot consolidate a cache with somehting of a different class (#{other.class})" unless self.class == other.class
    attrs = (self.date > other.date ? self : other).attributes.dup  # default all to last
    attrs.delete(:id)
    AGGR_BY_SUM.map{|col| last_attrs[col] = self.attributes[col] + other.attributes[col]}
    Cacher.new(attrs)
  end


  # Unlike the +consolidate+ method, this adds _all_ attributes while using the latest date,
  # and returns them in a new Cacher object.
  def +(other)
    return self if other.nil?
    raise ArgumentError "cannot add cachers of different classes" unless self.class == other.class
    raise ArgumentError "cannot add cachers of different models" unless self.model_name == other.model_name
    date = (self.date > other.date ? self.date : other.date)
    attrs = self.attributes + other.attributes  # Hash addition is implemented in lib/functions.rb, and is a little hairy.
    attrs.merge!({ :date => date,    :id => -1,# why? :id -1??? ##   :model_name => "Sum",  # what was this doing here?  because you can sum a branchcache and a funderlinecache?  what use case?
                   :model_id => nil, :branch_id => nil, :center_id => nil })
    Cacher.new(attrs)
  end


end

class BranchCache < LoanAggregatingCache

  def self.recreate(date = Date.today, branch_ids = nil)
    self.update(date, branch_ids, true)
  end

  # Updates the caches
  # The +date+ default to today, the +branch_ids+ to nil (which causes all to
  # be updated) and +force+ defaults to false.
  def self.update(date = Date.today, branch_ids = nil, force = false)
    # updates the cache object for a branch
    # first create caches for the centers that do not have them
    debugger
    t0 = t = Time.now
    branch_ids = Branch.all.aggregate(:id) unless branch_ids
    branch_centers = Branch.all(:id => branch_ids).centers(:creation_date.lte => date).aggregate(:id)  # no need to exclude 'dissolved' centers?

    if force
      cids = branch_centers
      puts "#{cids.count} to update"  ### is this idiom for logging?  shouldn't we use some logger then?
    else  # unless we are forcing an update, only update the missing and stale centers
      ccs = CenterCache.all(:model_name => "Center", :branch_id => branch_ids, :date => date, :center_id.gt => 0)
      cached_centers = ccs.aggregate(:center_id)
      stale_centers = ccs.stale.aggregate(:center_id)
      cids = (branch_centers - cached_centers) + stale_centers
      puts "#{cached_centers.count} cached centers; #{branch_centers.count} total centers; #{stale_centers.count} stale; #{cids.count} to update"
    end

    return true if cids.blank?  # nothing to do
    # update all the centers for the date we want to update this branch for
    return false unless CenterCache.update(:center_id => cids, :date => date)  ### is CenterCache using a different argument structure?

    puts "UPDATED CENTER CACHES in #{(Time.now - t).round} secs"
    t = Time.now
    # then add up all the cached centers by branch
    branch_data_hash = CenterCache.all(:model_name => "Center", :branch_id => branch_ids, :date => date).group_by{|x| x.branch_id}.to_hash
    puts "READ CENTER CACHES in #{(Time.now - t).round} secs"

    t = Time.now
    # branch_data_hash now looks like:
    #     {:branch => [{...center data...}, {...center data...}], ...}
    # we have to convert this to:
    #     {:branch => {...sum of centers data...}, ...}
    branch_data = branch_data_hash.map do |bid,ccs|
      sum_centers = ccs.map do |c|
        # is_a? is not something to use in places like this because of the performance penalty.
        center_sum_attrs = c.attributes.select{|k,v| v.is_a? Numeric}.to_hash  ### why asssign to a never used local var?
      end
      [bid, sum_centers.reduce({}){|s,h| s+h}]  # i dont really understadn this line, does it use Hash addition?
    end.to_hash
    # TODO then add the loans that do not belong to any center
    # this does not exist right now so there is no code here.
    # when you add clients directly to the branch, do also update the code here
    ### do we allow clinet directly on the branch?  or should we create a reserved center for that, "the default center'?
    puts "CONSOLIDATED CENTER CACHES in #{(Time.now - t).round} secs"

    t = Time.now
    branch_data.map do |bid, c|
      bc = BranchCache.first_or_new({:model_name => "Branch", :model_id => bid, :date => date})
      attrs = c.merge(:branch_id => bid, :center_id => 0, :model_id => bid, :stale => false, :updated_at => DateTime.now)
      if bc.new?
        bc.attributes = attrs.merge(:id => nil, :updated_at => DateTime.now)
        bc.save
      else
        bc.update(attrs.merge(:id => bc.id))
      end
    end
    puts "WROTE BRANCH CACHES in #{(Time.now - t).round} secs"

    puts "COMPLETED IN #{(Time.now - t0).round} secs"
  end

  # This method returns a Hash like:
  #     { :branch_id => [..dates that have caches missing...] }
  # It takes an Array of branch ids in +branch_ids+ and a Hash of DM selection
  # options that is very descriptively named +hash+.
  def self.missing_dates(branch_ids = nil, hash = {})
    hash = hash.merge(:branch_id => branch_ids) if branch_ids
    def massage_to_hash(array_of_arrays)  # easier to read, more mem efficient and faster (not benchmarked though)
      h = {}; array_of_arrays.each{|x| h[x[0]] = x[1]}; h
    end
    # history_dates = LoanHistory.all(hash).aggregate(:branch_id, :date).group_by{|x| x[0]}.map{|k,v| [k,v.map{|x| x[1]}]}.to_hash
    history_dates = massage_to_hash(LoanHistory.all(hash).aggregate(:branch_id, :date))
    # cache_dates = BranchCache.all(hash).aggregate(:branch_id, :date).group_by{|x| x[0]}.map{|k,v| [k,v.map{|x| x[1]}]}.to_hash
    cache_dates   = massage_to_hash(BranchCache.all(hash).aggregate(:branch_id, :date))
    # hopefully we now have {:branch_id => :dates}   ### hopefully???
    missing_dates = history_dates - cache_dates
  end


  def self.missing_for_date(date = Date.today, branch_ids = nil, hash = {})
    BranchCache.missing_dates(branch_ids, hash.merge(:date => date))
  end

  ### staling is not doing much yet
  # def self.stale_for_date(date = Date.today, branch_ids = nil, hash = {})
  # end
end

class CenterCache < Cacher
  def self.update(hash = {})
    # creates a cache per center for branches and centers per the hash passed as argument
    debugger
    date = hash.delete(:date) || Date.today
    hash = hash.select{|k,v| [:branch_id, :center_id].include?(k)}.to_hash
    centers_data = CenterCache.create(hash.merge(:date => date, :group_by => [:branch_id,:center_id])).deepen.values.sum
    return false if centers_data == nil
    now = DateTime.now
    centers_data.delete(:no_group)
    return true if centers_data.empty?
    cs = centers_data.keys.flatten.map do |center_id|
      centers_data[center_id].merge({:type => "CenterCache",:model_name => "Center", :model_id => center_id, :date => date, :updated_at => now})
    end
    return false if cs.nil?
    sql = get_bulk_insert_sql("cachers", cs)
    raise unless CenterCache.all(:date => date, :center_id => centers_data.keys).destroy!
    repository.adapter.execute(sql)
  end


  def self.stalify(obj)
    # obj is either a Payment or a Loan
    t = Time.now
    cid = obj.c_center_id
    d = obj.is_a?(Payment) ? obj.received_on : obj.applied_on
    repository.adapter.execute("UPDATE cachers SET stale=1 WHERE center_id=#{cid} AND date >= '#{d.strftime('%Y-%m-%d')}' AND stale=0")
    puts "STALIFIED CENTERS in #{(Time.now - t).round(2)} secs"
  end

end
