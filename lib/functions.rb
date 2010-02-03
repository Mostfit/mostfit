# small monkey patch, real patch is submitted to extlib/merb/dm, hoping for inclusion soon
class Date
  WEEKDAYS = [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]
  def inspect
    "<Date: #{self.to_s}>"
  end

  def weekday
    #week starts on monday
    WEEKDAYS[cwday - 1]
  end

  def is_holiday?
    Holiday.all.include?(self)
  end

  def holiday_bump
    hols = $holidays
    new_date = self
    while hols.keys.include?(new_date)
      case hols[new_date].shift_meeting
        when :before
          new_date -= 1 
        when :after
          new_date += 1
      end
    end
    return new_date
  end  
  
  def holidays_shifted_today
    return self-1 if was_yesterday_holiday_shifted_today?
    return self+1 if is_tommorow_holiday_shifted_today?
    return self
  end
  
  def weekdays
    days       = []
    days      << self.weekday
    days      << self.holidays_shifted_today.weekday
    days.uniq
  end
  
  def to_yaml( opts={} )
    YAML::quick_emit( self, opts ) do |out|
      out.scalar( "tag:yaml.org,2002:timestamp", self.strftime("%Y-%m-%d"), :plain )
    end
  end

private
  def was_yesterday_holiday_shifted_today?
    yesterday = self-1
    return true if $holidays[yesterday] and $holidays[yesterday].shift_meeting==:after
    return false
  end

  def is_tommorow_holiday_shifted_today?
    yesterday = self+1
    return true if $holidays[yesterday] and $holidays[yesterday].shift_meeting==:before
    return false
  end
end

module Misfit
  module Config
    attr_accessor :hols

    def self.holidays
      @hols ||= Holiday.all.map{|h| [h.date, h]}.to_hash
    end

    def self.refresh_holidays
      @hols = nil
    end
  end
end

class Hash
  #Hash diffs are easy
  def diff(other)
    keys = self.keys
    keys.each.select{|k| self[k] != other[k]}
  end

  def / (other)
    rhash = {}
    keys.each do |k|
      if self.has_key?(k) and other.has_key?(k)
        rhash[k] = self[k]/other[k]
      else
        rhash[k] = nil
      end
    end
    rhash
  end

  def - (other)
    rhash = {}
    keys.each do |k|
      if has_key?(k) and other.has_key?(k)
        rhash[k] = self[k] - other[k]
      else
        rhash[k] = self[k]
      end
    end
    rhash
  end

  def +(other)
    rhash = {}
    (keys + other.keys).uniq.each do |k|
      if has_key?(k) and other.has_key?(k)
        rhash[k] = self[k] + other[k]
      elsif other.has_key?(k)
        rhash[k] = other[k]
      elsif has_key?(k)
        rhash[k] = self[k]
      end
    end
    rhash
  end

end

class String
  def join_snake(str='')
    self.split('_').map{|x| x}.join(str)
  end

  def camelcase(str='')
    self.split('_').map{|x| x.capitalize}.join(str)
  end
end


class Float
  alias_method :round_orig, :round
  def round(n=0)
    (self * (10.0 ** n)).round_orig * (10.0 ** (-n))
  end
end

module ExcelFormula
  def pmt(interest, installments, present_value, future_value, paid_before=1)  
    vPow = (1 + interest) ** installments
    actual_interest_rate = (paid_before == 0 ? interest : interest/(1 + interest))
    (vPow * present_value - future_value)/(vPow - 1) * actual_interest_rate
  end
end
