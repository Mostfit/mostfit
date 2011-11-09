class RepaymentStyle
  include DataMapper::Resource
  
  before :save, :convert_blank_to_nil

  property :id,       Serial
  property :name,     String, :unique => true
  property :style,    String
  property :round_total_to, Integer
  property :round_interest_to, Integer
  property :active, Boolean
  property :rounding_style, String
  property :force_num_installments, Boolean
  property :custom_principal_schedule, Text, :lazy => false
  property :custom_interest_schedule, Text, :lazy => false

  def to_s
    style
  end

  def self.from_csv(row, headers)
<<<<<<< HEAD
    obj = new(:name => row[headers[:name]], :style => row[headers[:style]],
              :custom_principal_schedule => row[headers[:custom_principal_schedule]], :active => true,
              :custom_interest_schedule => row[headers[:custom_interest_schedule]])
    [obj.save, obj]
=======
    obj = new([:name, :style, :round_total_to, :round_interest_to, :active, :rounding_style, :force_num_installments, :custom_principal_schedule, :custom_interest_schedule].map{|k| [k,row[headers[k]]] if headers[k]}.compact.to_hash)
    [obj.save, obj]

>>>>>>> new-layout
  end

  def convert_blank_to_nil
    self.attributes.each{|k, v|
      if v.is_a?(String) and v.empty? and (self.class.send(k).type == Integer or self.class.send(k).type == Float)
        self.send("#{k}=", nil)
      end
    }
  end

  def return_schedule(type)
    raise ArgumentError.new("type must be :principal or :interest") unless [:principal, :interest].include? type
    s = self.send("custom_#{type}_schedule")
    if s.index("?").nil? # only one amount
      rv = s.split(",").map{|a| a.to_f}
    else
      r_hash = s.gsub("\r\n","\n").split("\n").map{|x| x.split("?")}.to_hash.map{|k,v| [k.strip, v.split(",").map{|i| i.to_f}]}.to_hash
      rv = r_hash
    end
    rv
  end

  def principal_schedule(amount = nil)
    return @custom_prin_sched[amount.to_s] if @custom_prin_sched
    @custom_prin_sched = return_schedule(:principal)
    return @custom_prin_sched[amount.to_s]
  end

  def interest_schedule(amount = nil)
    return @custom_int_sched[amount.to_s] if @custom_int_sched
    @custom_int_sched = return_schedule(:interest)
    return @custom_int_sched[amount.to_s]
  end


end
