
class HoursAndMinutes < DataMapper::Type
  # stores 24:59 as integer 
  primitive Integer
  length 4

  def self.load(value, property)
    return nil if value.nil?
    raise ArgumentError.new("+value+ must be within (0..2359)") unless (0..2359).include? value
    colonize(value)
  end

  def self.dump(o, property)
    return nil if o.nil?
    h, m = 0, 0
    o = (o * 100).to_i if o.class == Float  # now float can be treated like ints
    if o.class == String
      o = colonize(o) if o.length == o.to_i.to_s.length  # when the string is representing an int
      raise ArgumentError.new("Cannot parse string '#{o}'") unless o =~ /(\d{1,2})[:.',]{0,1}(\d{1,2})/
      h, m = $1.to_i, $2.to_i
    elsif o.class == Fixnum
      h = o / 100
      m = o - (h*100)
    else
      raise ArgumentError.new("+o+ must be of type String, Fixnum or Float, or nil")
    end
    raise ArgumentError.new("invalid time, '#{o}', units out of range") unless (0..23).include? h and (0..59).include? m
    h * 100 + m
  end

  def self.typecast(value, property)
    value.kind_of?(HoursAndMinutes) ? value : load(value, property)
  end

  private
  def self.colonize(i)  # int or string to "12:12"
    i = i.to_s.rjust(4, '0')
    i[0..1]+':'+i[2..3]
  end
end



class Weekday < DataMapper::Type
  # stores weekdays as integers 1:monday, 2:tues, etc.
  primitive Integer
  length 1

  DAYS_OF_THE_WEEK = [nil, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]
  
  def self.load(value, property)
    return nil if value.nil?
    raise ArgumentError.new("+value+ must be within (1..7)") unless (1..7).include? value.to_i
    DAYS_OF_THE_WEEK[value]
  end

  def self.dump(value, property)
    return nil if value.nil?
    # plurialized weekday names are allowed ("Mondays", "thursday", "SUNDAY", :sunday)
    if value.class == String
      DAYS_OF_THE_WEEK.index value.downcase.singularize.to_sym
    elsif value.class ==  Symbol
      DAYS_OF_THE_WEEK.index value
    else
      raise ArgumentError.new("+value+ must be of type String or Symbol, or nil")
    end
  end

  def self.typecast(value, property)
    value.kind_of?(Weekday) ? value : load(value, property)
  end
end