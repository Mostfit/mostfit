# mixin to parse dates for models that have properties of type date and use the date_select_for helper

module DateParser

  # parses the date if nil, Date or Mash, otherwise throw an exception
  def parse_dates
    cols = properties.to_a.find_all{ |x| x.type == Date }.map{ |x| x = x.name }
    cols.each do |col|
      value = send(col)
      if value.class == Date or value.class == NilClass
        next
      elsif value.class == Mash
        send("#{col.to_s}=".to_sym, parse_date(value))
      elsif value.class == String
        send("#{col.to_s}=".to_sym, parse_date(value))
      else
        raise "Unknown input type for #{col.to_s}, #{value.class}"
      end
    end
  end

  # function for parsing individual date values, takes a Mash or a string date, outputs a Date or nil
  def parse_date(value)
    return Date.parse(value) if value.is_a? String and not value.blank?    
    args = [value[:year].to_i, value[:month].to_i, value[:day].to_i]
    return nil if args.include? 0
    begin
      Date.new(*args)
    rescue
      raise "Could not parse a date from #{args.inspect}"
    end
  end
end
