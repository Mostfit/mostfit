class CacheObserver
  include DataMapper::Observer

  observe Payment, Loan

  def self.get_date(obj)
    date = obj.respond_to?(:applied_on) ? obj.applied_on : (obj.respond_to?(:received_on) ? obj.received_on : enil)
  end

  def self.make_stale(obj)
    center_id = obj.c_center_id
    date = CacheObserver.get_date(obj)
    loan = obj.is_a?(Loan) ? obj : obj.loan
    info = loan.info(date)
    CenterCache.stalify(:center_id => obj.c_center_id, :date => date)  if date
    FundingLineCache.stalify(:center_id => obj.c_center_id, :date => date, :model_id => info.funding_line_id)
  end

  after :create do
    CacheObserver.make_stale(self)
  end
  
  after :update do
    CacheObserver.make_stale(self)
  end

end
