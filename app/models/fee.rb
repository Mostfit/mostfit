class Fee
  include DataMapper::Resource
  
  PAYABLE = [:loan_applied_on, :loan_approved_on, :loan_disbursal_date, :loan_scheduled_first_payment_date, :loan_first_payment_date, :client_grt_pass_date, :client_date_joined]

  property :id,            Serial
  property :name,          String, :nullable => false
  property :percentage,    Float
  property :amount,        Integer
  property :min_amount,    Integer
  property :max_amount,    Integer
  property :payable_on,    Enum.send('[]',*PAYABLE), :nullable => false

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
    desc =  "#{name}: "
    desc += "#{percentage} %" if percentage and percentage>0
    desc += " Amount Rs. #{amount}" if amount
    if min_amount and max_amount and max_amount!=min_amount
      desc += " Subject to a minimum of  Rs. #{min_amount}" if min_amount
      desc += ", maximum of Rs. #{max_amount}" if max_amount
    end
    desc
  end

  def self.payable_dates
    PAYABLE
  end

  def fees_for(loan)
    return amount if amount
    return [[min_amount || 0 , (percentage ? percentage * loan.amount : 0)].max, max_amount || (1.0/0)].min
  end
end
