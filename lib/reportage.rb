# Reportage - the Mostfit Reporting Library

class BucketResult < Hash

  # The results from a Bucket#columns is stored as a BucketResult so that we can
  # print fancy tables and stuff

  def hash_to_string(title = "", separator = "|", width = 10, padding = 4)
    titles = [title] + self.values.first.keys
    puts titles.map{|t| t.to_s[0..width - 1].rjust(width - padding/2).ljust(width)}.join(separator)
    keys = self.keys.first
    numeric_keys = true if Float(self.keys.first) rescue false
    if numeric_keys
      h = self.map{|k,v| [k.to_i,v]}.to_hash
    else
      h = self
    end
    oink = h.keys.sort.map{|k| v = h[k];[k] + v.map{|_k,_v| (_v.is_a? Numeric) ? _v.round(2) : _v}}
    oink.map{|a| a.map{|s| s.to_s.rjust(width - padding/2).ljust(width)}}.map{|a| a.join(separator)}.join("\n")
  end

  def to_ascii_table(title = "", width = 10, padding = 4)
    hash_to_string(title, "|", width, padding)
  end
  
  def to_csv(title = "", width = 10, padding = 4)
    hash_to_string(title, ",", width, padding)
  end
end #BucketResult

class Bucket < Hash
  attr_accessor :_balances, :date, :date_from, :date_to

  def initialize(dates = {})
    set_dates(dates)
  end

  def set_dates(dates = {})
    dates.each{|k,v| instance_variable_set("@#{k.to_s}",v)}
  end

  def columns(cols)
    rv = BucketResult.new
    self.keys.each{|b| rv[b.to_s] = {}}
    cols.map do |function|
      dates = case method(function).arity
              when 0; []
              when 1; [@date]
              when 2; [@date_from, @date_to]
              end
      self.send(function, *dates).each do |b,v| 
        rv[b.to_s] = rv[b.to_s].merge(function => v)
      end
    end
    rv
  end
end #Bucket

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
  
  # Extend the DataMapper::Collection to allow bucketing
  
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
      

