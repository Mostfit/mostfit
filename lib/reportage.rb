# Reportage - the Mostfit Reporting Library



      
class LoanBucket < Hash

  attr_accessor :_balances

  def columns(cols, date)
    cols.map do |function| 
      self.send(function, date)
    end
  end
        
  def balances(date)
    return @_balances if @_balances
    @balances = self.map{|bucket, ids| [bucket, LoanHistory.sum_outstanding_for_loans(date, ids)]}.to_hash
  end
    
  def scheduled_outstanding_principal(date)
    self.map{|bucket, ids| [bucket, {:scheduled_outstanding_principal => balances(date)[bucket][0].scheduled_outstanding_principal.to_f}]}.to_hash
  end

  def actual_outstanding_principal(date)
    self.map{|bucket, ids| [bucket, {:actual_outstanding_principal => balances(date)[bucket][0].actual_outstanding_principal.to_f}]}.to_hash
  end

end

module DataMapper
  class Collection
    
    def bucket_by(buckets = nil)
      result = LoanBucket.new
      self.map do |x| 
        r = yield(x)
        if result.has_key?(r)
          result[r] << x.id
        else
          result[r] = [x.id]
        end
      end
      bucketed_results = LoanBucket.new
      if buckets
        buckets.map{|b| bucketed_results[b] = []}
        result.map do |k,v|
          bucket_found = false
          buckets.each_with_index do |b,i|
            if i < buckets.count - 1
              if (k > b and k <= buckets[i+1])
                bucketed_results[b] += v 
                bucket_found = true
              end
            end
          end
          bucketed_results[buckets.last] += v unless bucket_found
        end
        return bucketed_results
      else
        return result
      end
    end
  end
end
      

