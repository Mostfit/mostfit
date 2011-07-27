class RepaymentStyle
  include DataMapper::Resource
  
  before :save, :convert_blank_to_nil

  property :id,       Serial
  property :name,     String
  property :style,    String
  property :round_total_to, Integer
  property :round_interest_to, Integer
  property :active, Boolean
  property :rounding_style, String
  property :force_num_installments, Boolean
  property :custom_principal_schedule, Text
  property :custom_interest_schedule, Text

  def to_s
    style
  end

  def convert_blank_to_nil
    self.attributes.each{|k, v|
      if v.is_a?(String) and v.empty? and (self.class.send(k).type == Integer or self.class.send(k).type == Float)
        self.send("#{k}=", nil)
      end
    }
  end

  def return_schedule(type, amount = nil)
    raise ArgumentError ("type must be :principal or :interest") unless [:principal, :interest].include? type
    s = self.send("custom_#{type}_schedule")
    if s.index("?").nil? # only one amount
      rv = s.split(",").map{|a| a.to_f}
    else
      r_hash = s.gsub("\r\n","\n").split("\n").map{|x| x.split("?")}.to_hash.map{|k,v| [k.strip, v.split(",").map{|i| i.to_f}]}.to_hash
      raise ArgumentError("Must specify an amount as repayment style requires it") unless amount
      rv = r_hash[amount.to_s]
    end
    rv
  end

  def principal_schedule(amount = nil)
    return @custom_prin_sched if @custom_prin_sched
    @custom_prin_sched = return_schedule(:principal, amount)
  end

  def interest_schedule(amount = nil)
    return @custom_int_sched if @custom_int_sched
    @custom_int_sched = return_schedule(:interest,amount)
  end


end
