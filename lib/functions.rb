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
end


#Hash diffs are easy

class Hash
  def diff(other)
    keys = self.keys
    keys.each.select{|k| self[k] != other[k]}
  end
end

module ExcelFormula
  def pmt(interest, installments, present_value, future_value, paid_before=1)  
    vPow = (1 + interest) ** installments
    actual_interest_rate = (paid_before == 0 ? interest : interest/(1 + interest))
    (vPow * present_value - future_value)/(vPow - 1) * actual_interest_rate
  end
end
