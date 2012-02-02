class Cacher
  # like LoanHistory but for anything that has loans
  include DataMapper::Resource

  property :type,                            Discriminator, :key => true
  property :date,                            Date, :nullable => false, :index => true, :key => true
  property :model_name,                      String, :nullable => false, :index => true, :key => true
  property :model_id,                        Integer, :nullable => false, :index => true, :unique => [:model_name, :date], :key => true
  property :branch_id,                       Integer, :index => true, :key => true
  property :center_id,                       Integer, :index => true, :key => true
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
    FLOW_COLS.each{|col| attrs[col] = my_attrs[col] + other_attrs[col]}    

    me = self.attributes; other = other.attributes;

    attrs[:stale] = me[:stale] || other[:stale]
    Cacher.new(attrs)
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
    attrs[:model_id] = nil; attrs[:branch_id] = nil; attrs[:center_id] = nil;
    attrs[:stale] = me[:stale] || other[:stale]
    Cacher.new(attrs)
  end

  # freshens all the stale caches datewise
  def self.process_queue
  end


end

class BranchCache < Cacher

  def self.recreate(date = Date.today, branch_ids = nil)
    self.update(:date => date, :branch_ids => branch_ids, :force => true)
  end

  def self.update(date = Date.today, branch_ids = nil, force = false)
    # cache updates must be pristine, so rollback on failure.
    BranchCache.transaction do |t|
      # updates the cache object for a branch
      # first create caches for the centers that do not have them
      t0 = Time.now; t = Time.now;
      branch_ids = Branch.all.aggregate(:id) unless branch_ids
      #branch_centers = Branch.all(:id => branch_ids).centers.aggregate(:id)
      branch_centers = q("SELECT id FROM centers WHERE #{get_where_from_hash(:branch_id => branch_ids)}")
      # unless we are forcing an update, only work with the missing and stale centers
      unless force
        hash = {:model_name => "Center", :branch_id => branch_ids, :date => date}
        #ccs = CenterCache.all(hash)
        # nothing like some raw SQL to speed up queries.....dammmitt!
        cached_centers = repository.adapter.query("SELECT center_id FROM cachers WHERE type = 'CenterCache' AND center_id > 0 AND #{get_where_from_hash(hash)}").map(&:to_i) #ccs.aggregate(:center_id)
        stale_centers = repository.adapter.query("SELECT center_id FROM cachers WHERE type = 'CenterCache' AND center_id > 0 AND stale = 1 AND #{get_where_from_hash(hash)}").map(&:to_i) #ccs.aggregate(:center_id)
        #stale_centers = ccs.stale.aggregate(:center_id)
        cids = (branch_centers - cached_centers) + stale_centers
        puts "#{cached_centers.count} cached centers; #{branch_centers.count} total centers; #{stale_centers.count} stale; #{cids.count} to update"
      else
        cids = branch_centers
        puts " #{cids.count} to update"
      end

      return true if cids.blank? #nothing to do
      # update all the centers for today
      chunks = (cids.count/CHUNK_SIZE.to_f).ceil
      begin
        _t = Time.now
        cids.chunk(CHUNK_SIZE).each_with_index do |_cids, i|
          puts "DOING chunk #{i+1} of #{chunks}...."
          (CenterCache.update(:center_id => _cids, :date => date))
          print "#{(Time.now - _t).round(2)} secs"
        end
      rescue Exception => e
        puts "#{e}\n#{e.backtrace[0..400]}"
        return false
      end
      puts "UPDATED CENTER CACHES in #{(Time.now - t).round} secs"
      t = Time.now
      # then add up all the cached centers by branch
      relevant_branch_ids = q("SELECT DISTINCT branch_id FROM centers WHERE #{get_where_from_hash(:id => cids)}")
      # branch_data_hash = CenterCache.all(:model_name => "Center", :branch_id => relevant_branch_ids, :date => date).group_by{|x| x.branch_id}.to_hash
      h = {:model_name => "Center", :branch_id => relevant_branch_ids, :date => date, :type => 'CenterCache'}
      branch_data_hash = q(%Q{
                           SELECT * 
                           FROM cachers 
                           WHERE #{get_where_from_hash(h)}}).group_by{|x| x.branch_id}.to_hash
      puts "READ CENTER CACHES in #{(Time.now - t).round} secs"
      t = Time.now

      # we now have {:branch => [{...center data...}, {...center data...}]}, ...
      # we have to convert this to {:branch => { sum of centers data }, ...}
      numeric_attributes = branch_data_hash.first[1][0].attributes.select{|k,v| k if v.is_a? Numeric}.to_hash.keys
      branch_data = branch_data_hash.map do |bid,ccs|
        sum_centers = ccs.map do |c|
          center_sum_attrs = c.attributes.only(*numeric_attributes)
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
    t = Time.now
    date = hash.delete(:date) || Date.today
    hash = hash.only(:center_id)
    
    # we can make an optimisation here which will kick in when we are updating days caches sequentially
    # for a given center which does not have a row in the loan history table, we can pick the preceding days caches 
    # if it is not stale

    centers_without_loan_history_row = hash[:center_id] - q("SELECT center_id FROM loan_history WHERE #{get_where_from_hash(hash.merge(:date => date))}")
    h = {:type => "CenterCache", :center_id => centers_without_loan_history_row, :date => (date - 1), :stale => false}
    ng_pmts = FLOW_COLS.map{|c| [c,0]}.to_hash #because the flows are all 0 for this date
    centers_data_wo = centers_without_loan_history_row.blank? ? {} : q(%Q{SELECT *
                           FROM cachers
                           WHERE #{get_where_from_hash(h)}}).map{|c| [c.center_id, c.attributes.merge(ng_pmts)]}.to_hash
    # drop the stale ones from the list
    centers_to_not_update = centers_data_wo.keys
    puts "FOUND #{centers_to_not_update.count} centers without loan history row for #{date} in #{Time.now - t} secs"
    
    # now carry on without the unnecessary centers
    hash[:center_id] = hash[:center_id] - centers_to_not_update
    return true if hash[:center_id].blank? and centers_to_not_update.blank?
    centers_data = hash[:center_id].blank? ? {} : CenterCache.create(hash.merge(:date => date, :group_by => [:branch_id,:center_id]))
    centers_data += centers_data_wo
    return false if centers_data == nil
    now = DateTime.now
    return true if centers_data.empty?
    sql = get_bulk_insert_sql("cachers", centers_data.values, {:type => "CenterCache",:model_name => "Center", :date => date, :updated_at => now, :created_at => now, :stale => false}, [:end_date])
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
    # pmts = LoanHistory.composite_key_sum(LoanHistory.all(hash.merge(:date => date)).aggregate(:composite_key), group_by, flow_cols)
    pmts = LoanHistory.composite_key_sum(LoanHistory.get_composite_keys(hash.merge(:date => date)), group_by, flow_cols)
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
      extra = balances[k] ? {:model_id => k[1]} : {:center_id => k[1], :branch_id => k[0], :model_id => k[1]} # for ng rows, we need to insert center_id and branch_id
      [k[1], _p.merge(_b).merge(extra)]
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
    sql = %Q{
        UPDATE cachers 
        SET stale=1 
        WHERE (center_id=#{cid} 
             OR (center_id = 0 
               AND branch_id = #{@center.branch_id})) 
           AND date >= '#{d.strftime('%Y-%m-%d')}' 
           AND stale=0 
           AND type IN ('CenterCache','BranchCache')}
    repository.adapter.execute(sql)
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


class Cache < Cacher
  
  # this class is for caching according to properties other than branch and center id i.e. funding line, staff member, loan product and
  # any other arbitrary collection of loan including portfolios
  # all references to funding line in comments is purely for illustration and not meant literally


  def self.update(hash = {})
    debugger
    # is our cache based off fields in the loan history table?
    base_model_name = self.to_s.gsub("Cache","")
    loan_history_field = "#{base_model_name.snake_case}_id".to_sym
    # creates a cache per funding line for branches and funding lines per the hash passed as argument
    date = hash.delete(:date) || Date.today
    force = hash.delete(:force) || false
    hash = hash.select{|k,v| [:branch_id, :center_id, loan_history_field].include?(k)}.to_hash

    unless force
      # the problem of doing 2 factor stalification - we might have within the same center some loans that belong to a stale funding line
      # and others that belong to other fuding lines.
      # therefore, the incremental update must necessarily be per loan_ids.
      # we have to find the loan ids in the stale funding line
      fl_caches = self.all(:center_id.not => 0, :date => date)
      stale_caches = fl_caches.stale.aggregate(:model_id, :center_id)
      missing_caches = LoanHistory.all(:date.gte => date).aggregate(loan_history_field, :center_id) - fl_caches.aggregate(:model_id, :center_id)
      caches_to_do = stale_caches + missing_caches
      unless caches_to_do.blank?
        ids = caches_to_do.map{|x| "(#{x.join(',')})"}
        sql = "select loan_id from loan_history where (#{loan_history_field}, center_id) in (#{ids.join(',')}) group by loan_id"
        loan_ids = repository.adapter.query(sql)
        hash[:loan_id] = loan_ids
      end
    end
    
    fl_data = self.create(hash.merge(:date => date, :group_by => [:branch_id, :center_id, loan_history_field])).deepen.values.sum
    return false if fl_data == nil
    now = DateTime.now
    fl_data.delete(:no_group)
    return true if fl_data.empty?
    fls = fl_data.map do |center_id,funding_line_hash|
      funding_line_hash.map do |fl_id, fl|
        fl_data[center_id][fl_id].merge({:type => self.to_s,:model_name => base_model_name, :model_id => fl_id, :date => date, :updated_at => now})
      end
    end.flatten
    if fls.nil?
      return false 
    end
    _fls = fls.map{|fl| fl.delete(loan_history_field); fl}
    sql = get_bulk_insert_sql("cachers", _fls)
    # destroy the relevant funding_line caches in the database
    debugger
    ids = fl_data.map{|center_id, models|
      models.map{|fl_id, data|
        [center_id, fl_id]
      }
    }
    ids = ids.flatten(1).map{|x| "(#{x.join(',')})"}.join(",")
    raise unless repository.adapter.execute("delete from cachers where model_name = '#{base_model_name}' and (center_id, model_id) in (#{ids})")
    repository.adapter.execute(sql)

    # now do the branch aggregates for each funding line cache
    Kernel.const_get(base_model_name).all.each do |fl|
      debugger
      relevant_branch_ids = (hash[:center_ids] ? Center.all(:id => hash[:center_ids]) : Center.all).aggregate(:branch_id)
      branch_data_hash = self.all(:model_name => base_model_name, :branch_id => relevant_branch_ids, :date => date, :center_id.gt => 0, :model_id => fl.id).group_by{|x| x.branch_id}.to_hash

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

      branch_data.map do |bid, c|
        debugger
        bc = self.first_or_new({:model_name => base_model_name, :branch_id => bid, :date => date, :model_id => fl.id, :center_id => 0})
        attrs = c.merge(:branch_id => bid, :center_id => 0, :model_id => fl.id, :stale => false, :updated_at => DateTime.now, :model_name => base_model_name)
        if bc.new?
          bc.attributes = attrs.merge(:id => nil, :updated_at => DateTime.now)
          bc.save
        else
          bc.update(attrs.merge(:id => bc.id))
        end
      end
    end
  end


  def self.create(hash = {})
    # creates a cacher from loan_history table for any arbitrary condition. Also does grouping
    debugger
    base_model_name = self.to_s.gsub("Cache","")
    loan_history_field = "#{base_model_name.snake_case}_id".to_sym
    date = hash.delete(:date) || Date.today
    group_by = hash.delete(:group_by) || [:branch_id, :center_id, loan_history_field]
    cols = hash.delete(:cols) || COLS
    flow_cols = FLOW_COLS
    balances = LoanHistory.latest_sum(hash,date, group_by, cols)
    pmts = LoanHistory.composite_key_sum(LoanHistory.all(hash.merge(:date => date)).aggregate(:composite_key), group_by, flow_cols)
    # if there are no loan history rows that match today, then pmts is just a single hash, else it is a hash of hashes

``    # set up some default hashes to use in case we get dodgy results back.
    ng_pmts = flow_cols.map{|c| [c,0]}.to_hash # ng = no good. we return this if we get dodgy data
    ng_bals = cols.map{|c| [c,0]}.to_hash # ng = no good. we return this if we get dodgy data
    # workaround for the situation where no rows get returned for centers without loans.
    # this makes it very difficult to find missing center caches so we must have a row for all centers, even if it is full of zeros
    # find all relevant centers

    # if we are doing only a subset of centers / funding lines, we do it using loan_ids.
    # so if we have some loan_ids, then we just use these
    if hash[:loan_id]
      universe = LoanHistory.all(hash).aggregate(:branch_id, :center_id, loan_history_field)
    else
      # else we find all the centers that we're interested in
       _u = Center.all(hash[:center_id] ? {:id => hash[:center_id]} : {}).aggregate(:branch_id, :id) # array of [[:branch_id, :center_id]...] for all branches and centers
      # now add the funding line id to each of these universes
      universe = Kernel.const_get(base_model_name).all.map{|f| 
        __u = Marshal.load(Marshal.dump(_u)) # effing ruby pass by reference....my ass
        __u.map{|u| u.push(f.id)}
      }.flatten(1)
    end
    universe.map do |k| 
      _p = pmts[k] || ng_pmts
      _b = balances[k] || ng_bals
      extra = balances[k] ? {} : {:center_id => k[1], :branch_id => k[0], :model_id => k[2]} # for ng rows, we need to insert center_id and branch_id
      [k, _p.merge(_b).merge(extra)]
    end.to_hash

  end


  # executes an SQL statement to mark all center caches and branch caches for this center as stale. Only does this for cachers on or after options[:date]
  # params [Hash] a hash of options thus {:center_id => Integer, :date => Date or String, :model_id => Integer}
  def self.stalify(options = {})
    base_model_name = self.to_s.gsub("Cache","")
    loan_history_field = "#{base_model_name.snake_case}_id".to_sym

    t = Time.now
    raise NotAcceptable unless [:center_id, :date].map{|o| options[o]}.compact.size == 2
    cid = options[:center_id]
    @center = Center.get(cid)
    d = options[:date].class != Date ? (Date.parse(options[:date]) rescue nil) : options[:date]
    raise ArgumentError.new("Cannot parse date") unless d

    sql = %Q{
      UPDATE cachers SET stale=1 
      WHERE model_name = '#{base_model_name}'
        AND model_id=#{options[:model_id]} 
        AND (center_id = #{cid} 
           OR (center_id = 0 AND branch_id = #{@center.branch_id}) 
           OR (branch_id = 0 and center_id = 0 and model_id = #{options[:model_id]})
          ) 
        AND date >= '#{d.strftime('%Y-%m-%d')}' AND stale=0}
    repository.adapter.execute(sql)
  end

  # finds the missing caches given some caches 
  def self.missing(selection)
    base_model_name = self.to_s.gsub("Cache","")
    loan_history_field = "#{base_model_name.snake_case}_id".to_sym

    bs = self.all(selection).aggregate(:date, :model_id).group_by{|x| x[0]}.to_hash.map{|k,v| [k, v.map{|x| x[1]}]}.to_hash
    # bs is a hash of {:date => [:center_id,...]}
    date = selection.delete(:date)
    selection[:id] = selection.delete(loan_history_field) if selection[loan_history_field]
    hs = Kernel.const_get(base_model_name).all(selection.merge(:creation_date.lte => date)).aggregate(:id)
    date.map{|d| [d,hs - (bs[d] || [])]}.to_hash
  end
end


class FundingLineCache < Cache
end

class LoanProductCache < Cache
end

