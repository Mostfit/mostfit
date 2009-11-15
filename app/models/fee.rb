class Fee
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String
  property :percentage, Float
  property :amount, Integer
  property :min_amount, Integer
  property :max_amount, Integer
  property :payable_on, Enum[:applied_on, :approved_on, :disbursal_date, :scheduled_first_payment_date, :first_payment_date]

  # anything else will have to be ruby code - sorry

  def fees_for(loan)
    return amount if amount
    return [[min_amount || 0 , percentage * loan.amount].max, max_amount || (1.0/0)].min
  end
end
