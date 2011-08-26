class Cacher
  # like LoanHistory but for anything
  include DataMapper::Resource
  property :date,                            Date, :nullable => false, :index => true, :key => true
  property :model_name,                      String, :nullable => false, :index => true, :key => true
  property :model_id,                        Integer, :nullable => false, :index => true, :key => true
  property :branch_id,                       Integer, :index => true
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

  property :created_at,                      DateTime

  property :stale,                           Boolean, :default => false


  def self.bulk_update_caches(set,where)
    Cacher.all(where).update(set)
  end

  def self.lock_caches(hash = {})
    
  end    

  def self.update_branch_cache(branch_id, date = Date.today)
    # updates the cache object for a branch
    debugger
    branch_data = LoanHistory.latest_sum({:status => [:disbursed, :outstanding], :branch_id => branch_id}, date)
    bc = Cacher.first_or_new({:model_name => "Branch", :model_id => branch_id, :date => date})
    branch_data.each{|k,v| bc.send("#{k}=".to_sym, v)}
    bc.branch_id = branch_id
    return bc.save
  end

  def self.update_centers_cache_by_branch(branch_id = nil, date = Date.today)
    debugger
    # updates the cache object for centers in a branch (or all centers if no branch specified)
    hash = branch_id ? {:branch_id => branch_id} : {}
    # we go a bit round about way because we want the branch_id in the row as well
    centers_data = LoanHistory.latest_sum(hash, date, [:branch_id,:center_id]).deepen.values
    centers_data.keys.flatten.map do |center_id|
      debugger
      cc = Cacher.first_or_new({:model_name => "Center", :model_id => center_id, :date => date})
      centers_data[[center_id]].each{|k,v| cc.send("#{k}=".to_sym, v)}
      cc.branch_id
      puts center_id
      cc.save
    end
  end



end

