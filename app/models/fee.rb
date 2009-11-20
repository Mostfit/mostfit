class Fee
  include DataMapper::Resource
  
  PAYABLE = [:applied_on, :approved_on, :disbursal_date, :scheduled_first_payment_date, :first_payment_date]

  property :id, Serial
  property :name, String, :nullable => false
  property :percentage, Float
  property :amount, Integer
  property :min_amount, Integer
  property :max_amount, Integer
  property :payable_on, Enum.send('[]',*PAYABLE)

  has n, :loan_products, :through => Resource

  # anything else will have to be ruby code - sorry
  
  validates_with_method :amount_is_okay
  validates_with_method :min_lte_max
  
  def amount_is_okay
    return true if (amount or percentage)
    return [false, "Either an amount or a percentage must be specified"]
  end

  def min_lte_max
    return true if (min_amount and max_amount and min_amount <= max_amount) or (min_amount.nil? or max_amount.nil?)
    return [false, "Minimum amount must be less than maximum amount"]
  end

  def description
    desc = ""
    desc += "#{percentage} %" if percentage
    desc += "#{amount}" if amount
    desc += "minimum: #{min_amount}" if min_amount
    desc += "maximum: #{max_amount}" if max_amount
    desc
  end

  def self.payable_dates
    PAYABLE
  end

  def fees_for(loan)
    return amount if amount
    return [[min_amount || 0 , percentage * loan.amount].max, max_amount || (1.0/0)].min
  end
end
