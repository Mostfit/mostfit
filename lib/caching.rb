module Mostfit
  module Caching
    def caches(hash = {})
      Cacher.all(hash.merge(:model_name => self.model.to_s, :model_id => self.id))
    end

    def cache(date)
      Cacher.first(:model_name => self.model.to_s, :model_id => self.id, :date => date)
    end

    def cache_for(date)
      # creates the cache if it does not exist
      c = cache(date)
      return c if c
      id_sym = "#{self.model.to_s.snake_case}_id".to_sym
      row = LoanHistory.latest_sum({:status => [:disbursed, :outstanding], id_sym => self.id}, date)
      cc = Cacher.new({:model_name => self.model.to_s, :model_id => self.id, :date => date})
      row.each{|k,v| cc.send("#{k}=".to_sym, v)}
      cc.save
      return cc
    end

    def stalify(date)
      repository.adapter.execute(%Q{UPDATE cachers 
                                    SET stale = 1 
                                    WHERE model_name = '#{self.model.to_s}' AND model_id = #{self.id}
                                    AND (stale = 0 OR  stale is NULL) AND date >= '#{date.strftime('%Y-%m-%d')}'})
    end
                                   
      
  end
end
    
