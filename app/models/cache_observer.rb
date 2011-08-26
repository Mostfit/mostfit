class CacheObserver
  include DataMapper::Observer

  observe Journal

  after :save do
    if self.model == Payment
      self.loan.client.center.stalify(self.received_on)
    elsif self.model == Loan
      self.client.center.cache.stalify(self.applied_on)
    end
  end


end
