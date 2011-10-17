class CacheObserver
  include DataMapper::Observer

  observe Payment, Loan

  after :create do
    CenterCache.stalify(self)
  end
  
  after :update do
    CenterCache.stalify(self)
  end

end
