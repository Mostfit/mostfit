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
    @hols = HOLIDAYS
    new_date = self
    while @hols.keys.include?(new_date)
      case @hols[new_date].shift_meeting
        when :before
          new_date -= 1 
        when :after
          new_date += 1
      end
    end

    return new_date
  end
#  def to_s
#    "#{year}-#{month}-#{day} (#{weekday.to_s[0..2]})"
#  end
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

module ExcelFormula
  def pmt(interest, installments, present_value, future_value, paid_before=1)  
    vPow = (1 + interest) ** installments
    actual_interest_rate = (paid_before == 0 ? interest : interest/(1 + interest))
    (vPow * present_value - future_value)/(vPow - 1) * actual_interest_rate
  end
end
