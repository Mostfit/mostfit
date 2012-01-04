class Cacher
  # like LoanHistory but for anything that has loans
  include DataMapper::Resource

  property :type,                            Discriminator, :key => true
  property :date,                            Date, :nullable => false, :index => true, :key => true
  property :model_name,                      String, :nullable => false, :index => true, :key => true
  property :model_id,                        Integer, :nullable => false, :index => true, :unique => [:model_name, :date], :key => true
  property :branch_id,                       Integer, :index => true, :key => true
  property :center_id,                       Integer, :index => true, :key => true
  property :funding_line_id,                 Integer, :index => true
  property :scheduled_outstanding_total,     Float, :nullable => false
  property :scheduled_outstanding_principal, Float, :nullable => false
  property :actual_outstanding_total,        Float, :nullable => false
  property :actual_outstanding_principal,    Float, :nullable => false
  property :actual_outstanding_interest,     Float, :nullable => false
  property :scheduled_principal_due,         Float, :nullable => false
  property :scheduled_interest_due,          Float, :nullable => false

  property :principal_due,                   Float, :nullable => false
  property :interest_due,                    Float, :nullable => false
  property :principal_due_today,             Float, :nullable => false # this is the principal and interest 
  property :interest_due_today,              Float, :nullable => false  #that has become payable today

  property :principal_paid,                  Float, :nullable => false
  property :interest_paid,                   Float, :nullable => false
  property :total_principal_due,             Float, :nullable => false
  property :total_interest_due,              Float, :nullable => false
  property :total_principal_paid,            Float, :nullable => false
  property :total_interest_paid,             Float, :nullable => false
  property :advance_principal_paid,          Float, :nullable => false
  property :advance_interest_paid,           Float, :nullable => false
  property :total_advance_paid,              Float, :nullable => false
  property :advance_principal_paid_today,    Float, :nullable => false
  property :advance_interest_paid_today,     Float, :nullable => false
  property :total_advance_paid_today,        Float, :nullable => false
  property :advance_principal_adjusted,      Float, :nullable => false
  property :advance_interest_adjusted,       Float, :nullable => false
  property :advance_principal_adjusted_today,      Float, :nullable => false
  property :advance_interest_adjusted_today,       Float, :nullable => false
  property :total_advance_adjusted_today,   Float, :nullable => false
  property :advance_principal_outstanding,   Float, :nullable => false  #
  property :advance_interest_outstanding,    Float, :nullable => false  # these are adjusted balances
  property :total_advance_outstanding,       Float, :nullable => false  #
  property :principal_in_default,            Float, :nullable => false
  property :interest_in_default,             Float, :nullable => false
  property :total_fees_due,                  Float, :nullable => false
  property :total_fees_paid,                 Float, :nullable => false
  property :fees_due_today,                  Float, :nullable => false
  property :fees_paid_today,                 Float, :nullable => false
  property :principal_at_risk,               Float, :nullable => false

  # we need to track also the changes in status
  # i.e. from approved to disbursed, etc.

  STATUSES.each do |status|
    property "#{status.to_s}_count".to_sym,  Integer, :nullable => false, :default => 0
    property "#{status.to_s}".to_sym,        Float,   :nullable => false, :default => 0
  end

  property :created_at,                      DateTime
  property :updated_at,                      DateTime

  property :stale,                           Boolean, :default => false

  COLS =   [:scheduled_outstanding_principal, :scheduled_outstanding_total, :actual_outstanding_principal, :actual_outstanding_total, :actual_outstanding_interest,
          :total_interest_due, :total_interest_paid, :total_principal_due, :total_principal_paid,
          :principal_in_default, :interest_in_default, :total_fees_due, :total_fees_paid, :total_advance_paid, :advance_principal_paid, :advance_interest_paid,
          :advance_principal_adjusted, :advance_interest_adjusted, :advance_principal_outstanding, :advance_interest_outstanding, :total_advance_outstanding, :principal_at_risk, 
          :outstanding_count, :outstanding]
  FLOW_COLS = [:principal_due, :principal_paid, :interest_due, :interest_paid,
               :scheduled_principal_due, :scheduled_interest_due, :advance_principal_adjusted, :advance_interest_adjusted,
               :advance_principal_paid, :advance_interest_paid, :advance_principal_paid_today, :advance_interest_paid_today, :fees_due_today, :fees_paid_today,
               :principal_due_today, :interest_due_today, :total_advance_paid_today, :advance_principal_adjusted_today, :advance_interest_adjusted_today, 
               :total_advance_adjusted_today] + STATUSES.map{|s| [s, "#{s}_count".to_sym] unless s == :outstanding}.compact.flatten
  CALCULATED_COLS = [:principal_defaulted_today, :interest_defaulted_today, :total_defaulted_today]
  


  # some convenience functions
  def total_paid
    principal_paid + interest_paid + fees_paid_today
  end

  def total_due
    principal_due + interest_due + fees_due_today
  end

  def total_advance_paid_today
    advance_principal_paid_today + advance_interest_paid_today
  end

  def total_advance_paid
    advance_principal_paid + advance_interest_paid
  end

  def total_advance_os
    advance_principal_outstanding + advance_interest_outstanding
  end


  def total_advance_adjusted
    advance_principal_adjusted + advance_interest_adjusted
  end

  def total_default
    (principal_in_default + interest_in_default).abs
  end

  def principal_defaulted_today
    [scheduled_principal_due - principal_paid,0].max
  end

  def interest_defaulted_today
    [scheduled_interest_due - interest_paid,0].max
  end
  
  def total_defaulted_today
    principal_defaulted_today + interest_defaulted_today
  end


  def icash_interest_in_default
    [0,interest_in_default + total_advance_outstanding].min
  end

  def icash_total_default
    principal_in_default + icash_interest_in_default
  end

  def self.stale
    self.all(:stale => true)
  end

  def noop
    0
  end

  def method_missing(name, args)
    "N/A"
  end

  def self.get_missing_centers
    return [] if self.all.empty?
    branch_ids = self.aggregate(:branch_id)
    dates = self.aggregate(:date)
    branch_centers = Branch.all(:id => branch_ids).centers(:creation_date.lte => dates.min).aggregate(:branch_id, :id).group_by{|x| x[0]}.map{|k,v| [k, v.map{|x| x[1]}]}.to_hash
    cached_centers = Cacher.all(:model_name => "Center", :branch_id => branch_ids, :date => dates).aggregate(:branch_id, :center_id).group_by{|x| x[0]}.map{|k,v| [k, v.map{|x| x[1]}]}.to_hash
    branch_centers - cached_centers
  end



  def consolidate (other)
    # this not addition, it is consolidation
    # for cols (i.e balances) it takes the last balance, and for flow_cols i.e. payments, it takes the sum and returns a new cacher
    # it is used for summing cachers across time
    return self if other.nil?
    raise ArgumentError "cannot add cacher to something that is not a cacher" unless other.is_a? Cacher
    raise ArgumentError "cannot add cachers of different classes" unless self.class == other.class

    # first copy the attributes of the later one
    later_cacher = (self.date > other.date ? self : other)
    attrs = later_cacher.attributes.dup
    
    # for the FLOW_COLS, take the sum of the attributes in the two cachers
    my_attrs = self.attributes; other_attrs = other.attributes;
    FLOW_COLS.map{|col| attrs[col] = my_attrs[col] + other_attrs[col]}    

    me = self.attributes; other = other.attributes;

    # of course, simply doing the attributes means we have left out the "calculated" fields
    # calc_flow_fields = FLOW_COLS - attrs.keys
    #calc_flow_fields.each{|cff| attrs[cff] = self.send(cff) + other.send(cff)}
    #calc_col_fields = COLS - attrs.keys
    #calc_col_fields.each{|c| attrs[c] = later_cacher.send(c)}
    attrs[:stale] = me[:stale] || other[:stale]
    Cacher.new(my_attrs)
  end

  def + (other)
    # this adds all attributes to add two cachers together.
    # the date of the resultant cacher is the later date of the two
    return self if other.nil?
    raise ArgumentError.new("cannot add cacher to something that is not a cacher") unless other.is_a? Cacher
#    raise ArgumentError "cannot add cachers of different classes" unless self.class == other.class
    date = (self.date > other.date ? self.date : other.date)
    me = self.attributes; other = other.attributes;
    attrs = me + other; attrs[:date] = date; attrs[:model_name] = "Sum";

    # add the calculated fields
    #calc_flow_fields = FLOW_COLS - attrs.keys
    #calc_flow_fields.each{|cff| attrs[cff] = self.send(cff) + other.send(cff)}
    #calc_col_fields = COLS - attrs
    #calc_col_fields.each{|c| attrs[c] = self.send(c) + other.send(c)}

    
    attrs[:model_id] = nil; attrs[:branch_id] = nil; attrs[:center_id] = nil;
    Cacher.new(attrs)
  end

  # freshens all the stale caches datewise
  def self.process_queue
  end


end

class BranchCache < Cacher

  def self.recreate(date = Date.today, branch_ids = nil)
    self.update(date, branch_ids, true)
  end

  def self.update(date = Date.today, branch_ids = nil, force = false)
    # cache updates must be pristine, so rollback on failure.
    BranchCache.transaction do |t|
      # updates the cache object for a branch
      # first create caches for the centers that do not have them
      t0 = Time.now; t = Time.now;
      branch_ids = Branch.all.aggregate(:id) unless branch_ids
      branch_centers = Branch.all(:id => branch_ids).centers.aggregate(:id)

      # unless we are forcing an update, only work with the missing and stale centers
      unless force
        ccs = CenterCache.all(:model_name => "Center", :branch_id => branch_ids, :date => date, :center_id.gt => 0)
        cached_centers = ccs.aggregate(:center_id)
        stale_centers = ccs.stale.aggregate(:center_id)
        cids = (branch_centers - cached_centers) + stale_centers
        puts "#{cached_centers.count} cached centers; #{branch_centers.count} total centers; #{stale_centers.count} stale; #{cids.count} to update"
      else
        cids = branch_centers
        puts " #{cids.count} to update"
      end

      return true if cids.blank? #nothing to do
      # update all the centers for today
      chunks = cids.count/3000
      begin
        _t = Time.now
        cids.chunk(3000).each_with_index do |_cids,i|
          (CenterCache.update(:center_id => _cids, :date => date))
          puts "UPDATED #{i}/#{chunks} CACHES in #{(Time.now - _t).round} secs"
        end
      rescue Exception => e
        return false
      end
      puts "UPDATED CENTER CACHES in #{(Time.now - t).round} secs"
      t = Time.now
      # then add up all the cached centers by branch
      relevant_branch_ids = Center.all(:id => cids).aggregate(:branch_id)
      branch_data_hash = CenterCache.all(:model_name => "Center", :branch_id => relevant_branch_ids, :date => date).group_by{|x| x.branch_id}.to_hash
      puts "READ CENTER CACHES in #{(Time.now - t).round} secs"
      t = Time.now

      # we now have {:branch => [{...center data...}, {...center data...}]}, ...
      # we have to convert this to {:branch => { sum of centers data }, ...}

      branch_data = branch_data_hash.map do |bid,ccs|
        sum_centers = ccs.map do |c|
          center_sum_attrs = c.attributes.select{|k,v| v.is_a? Numeric}.to_hash
        end
        [bid, sum_centers.reduce({}){|s,h| s+h}]
      end.to_hash

      # TODO then add the loans that do not belong to any center
      # this does not exist right now so there is no code here.
      # when you add clients directly to the branch, do also update the code here

      puts "CONSOLIDATED CENTER CACHES in #{(Time.now - t).round} secs"
      t = Time.now
      branch_data.map do |bid, c|
        bc = BranchCache.first_or_new({:model_name => "Branch", :model_id => bid, :date => date})
        attrs = c.merge(:branch_id => bid, :center_id => 0, :model_id => bid, :stale => false, :updated_at => DateTime.now)
        bc.attributes = attrs
        bc.save
      end
      puts "WROTE BRANCH CACHES in #{(Time.now - t).round} secs"
      t = Time.now
      puts "COMPLETED IN #{(Time.now - t0).round} secs"
    end
  end

  # returns a hash of {:branch_id => [date1, date2...]} where dates are those where no caches exist for the branch
  #
  # param  [Integer or Array] branch_ids to filter for
  # param  [Hash]             selection hash to pass to datamapper 
  def self.missing_dates(branch_ids = nil, selection = {})
    selection = selection.merge(:branch_id => branch_ids) if branch_ids
    history_dates = LoanHistory.all(selection).aggregate(:branch_id, :date).group_by{|x| x[0]}.map{|k,v| [k,v.map{|x| x[1]}]}.to_hash
    cache_dates = BranchCache.all(selection).aggregate(:branch_id, :date).group_by{|x| x[0]}.map{|k,v| [k,v.map{|x| x[1]}]}.to_hash
    # hopefully we now have {:branch_id => :dates}
    missing_dates = history_dates - cache_dates
  end



  def self.missing_for_date(date = Date.today, branch_ids = nil, hash = {})
    BranchCache.missing_dates(branch_ids, hash.merge(:date => date))
  end

  def self.stale_for_date(date = Date.today, branch_ids = nil, hash = {})
  end
end

class CenterCache < Cacher

  # these have to be hooks, for obvious reasons, but for now we make do with some hardcoded magic!

  EXTRA_FIELDS = [:delayed_disbursals]
  def self.update(hash = {})
    # creates a cache per center for branches and centers per the hash passed as argument
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
    if cs.nil?
      return false 
    end
    sql = get_bulk_insert_sql("cachers", cs)
    raise unless CenterCache.all(:date => date, :center_id => centers_data.keys).destroy!
    repository.adapter.execute(sql) # raise an exception if anything goes wrong
  end

  def self.delayed_disbursal(hash = {})
    Loan.all(:scheduled_disbursal_date.lt => date, :disbursal_date => nil).aggregate(:branch_id, :center_id, :amount.sum)
  end

  def self.create(hash = {})
    # creates a cacher from loan_history table for any arbitrary condition. Also does grouping
    date = hash.delete(:date) || Date.today
    group_by = hash.delete(:group_by) || [:branch_id, :center_id]
    cols = hash.delete(:cols) || COLS
    flow_cols = FLOW_COLS
    balances = LoanHistory.latest_sum(hash,date, group_by, cols)
    pmts = LoanHistory.composite_key_sum(LoanHistory.all(hash.merge(:date => date)).aggregate(:composite_key), group_by, flow_cols)
    # if there are no loan history rows that match today, then pmts is just a single hash, else it is a hash of hashes
    ng_pmts = flow_cols.map{|c| [c,0]}.to_hash # ng = no good. we return this if we get dodgy data
    ng_bals = cols.map{|c| [c,0]}.to_hash # ng = no good. we return this if we get dodgy data
    # workaround for the situation where no rows get returned for centers without loans.
    # this makes it very difficult to find missing center caches so we must have a row for all centers, even if it is full of zeros
    
    # now hook in all the other functions that do not correspond to properties on loan history such as waiting borrowers, delayed disbursls etc.
    # extras = EXTRA_FIELDS.each do |hook|
    #  [hook, self.send(hook)]
    # end
    universe = Center.all(:id => hash[:center_id]).aggregate(:branch_id, :id) # array of [[:branch_id, :center_id]...] for all branches and centers
    universe.map do |k| 
      _p = pmts[k] || ng_pmts
      _b = balances[k] || ng_bals
      extra = balances[k] ? {} : {:center_id => k[1], :branch_id => k[0]} # for ng rows, we need to insert center_id and branch_id
      [k, _p.merge(_b).merge(extra)]
    end.to_hash

  end


  # executes an SQL statement to mark all center caches and branch caches for this center as stale. Only does this for cachers on or after options[:date]
  # params [Hash] a hash of options thus {:center_id => Integer, :date => Date or String}
  def self.stalify(options = {})
    t = Time.now
    raise NotAcceptable unless [:center_id, :date].map{|o| options[o]}.compact.size == 2
    cid = options[:center_id]
    @center = Center.get(cid)
    d = options[:date].class != Date ? (Date.parse(options[:date]) rescue nil) : options[:date]
    raise ArgumentError.new("Cannot parse date") unless d

    repository.adapter.execute("UPDATE cachers SET stale=1 WHERE center_id=#{cid} OR (center_id = 0 AND branch_id = #{@center.branch_id}) AND date >= '#{d.strftime('%Y-%m-%d')}' AND stale=0")
    # puts "STALIFIED CENTERS in #{(Time.now - t).round(2)} secs"

  end

  # finds the missing caches given some caches 
  def self.missing(selection)
    bs = self.all(selection).aggregate(:date, :center_id).group_by{|x| x[0]}.to_hash.map{|k,v| [k, v.map{|x| x[1]}]}.to_hash
    # bs is a hash of {:date => [:center_id,...]}
    # date = selection.delete(:date)
    # selection[:id] = selection.delete(:center_id) if selection[:center_id]
    # hs = Center.all(selection.merge(:creation_date.lte => date)).aggregate(:id)
    # centers cannot be searched by creation date because loans may be moved into the center
    # which have dates before the creation date
    hs = LoanHistory.all(selection).aggregate(:center_id)
    selection.delete(:date).map{|d| [d,hs - (bs[d] || [])]}.to_hash
  end



end
