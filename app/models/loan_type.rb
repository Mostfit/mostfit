class LoanType
  include DataMapper::Resource
  
  property :id, Serial

  property :name, String
  property :amount, Integer
  property :max_amount, Integer
  property :min_amount, Integer
  property :interest_rate, Integer
  property :max_interest_rate, Integer
  property :min_interest_rate, Integer
  property :installment_frequency, Enum.send('[]',*Loan.installment_frequencies)
  property :number_of_installments, Integer
  property :max_number_of_installments, Integer
  property :min_number_of_installments, Integer

end
