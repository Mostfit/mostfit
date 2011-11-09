class CacheObserver
  include DataMapper::Observer

  observe Payment, Loan

  def self.get_date(obj)
    date = obj.respond_to?(:applied_on) ? obj.applied_on : (obj.respond_to?(:received_on) ? obj.received_on : nil)
  end

  def self.make_stale(obj)
    center_id = obj.c_center_id
    date = CacheObserver.get_date(obj)
    CenterCache.stalify(:center_id => obj.c_center_id, :date => date)  if date
  end

  after :create do
    CacheObserver.make_stale(self)
  end
  
  after :update do
    CacheObserver.make_stale(self)
  end

end
