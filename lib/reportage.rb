# Reportage - the Mostfit Reporting Library

# TODO - convert LoanBucket into sublass of Bucket
#      - use aggregate for database fields to speed things up
      

class Bucket < Hash
  def columns(cols, date)
    rv = {}
    self.keys.each{|b| rv[b.to_s] = {}}
    cols.map do |function| 
      self.send(function, date).each do |b,v| 
        rv[b.to_s] = rv[b.to_s].merge(function => v)
      end
    end
    rv
  end
end

# Conjure a bucket class on demand ;). So, we don't have to define empty bucket
# classes for each model that we want to use bucketing with.
module Kernel
  def self.const_missing(name)
    if name.to_s =~ /Bucket\z/
      const_set(name, Class.new(Bucket))
    else
      super
    end
  end
end

class LoanBucket < Bucket

  attr_accessor :_balances

  def balances(date)
    return @_balances if @_balances
    @balances = self.map{|bucket, ids| [bucket, LoanHistory.sum_outstanding_for_loans(date, ids)]}.to_hash
  end
    
  def scheduled_outstanding_principal(date)
    self.map{|bucket, ids| [bucket, balances(date)[bucket][0].scheduled_outstanding_principal.to_f]}.to_hash
  end

  def actual_outstanding_principal(date)
    self.map{|bucket, ids| [bucket, balances(date)[bucket][0].actual_outstanding_principal.to_f]}.to_hash
  end

end

module DataMapper
  class Collection
    
    def bucket_by(buckets = nil)
      result = Kernel.const_get("#{self.first.model.to_s}Bucket").new {|h, k| h[k] = []}

      if buckets.is_a? Symbol
        # some properties might be lazily loaded, so first make sure they are
        # available, and then aggregate
        all(:fields => [buckets, :id]).aggregate(buckets, :id).each do |k, v|
          result[k] << v
        end
        return result
      end

      self.map do |x| 
        r = yield(x)
        result[r] << x.id
      end
      # result looks like this: {1000 => [1,4,5,.....loan_ids], 2000 => [x,y,z...loan_ids]}
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
      

