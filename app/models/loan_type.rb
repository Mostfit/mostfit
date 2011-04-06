class LoanType
  include DataMapper::Resource
  
  property :id, Serial

  property :name, String, :index => true
  property :max_amount, Integer, :index => true
  property :min_amount, Integer, :index => true
  property :max_interest_rate, Integer, :index => true
  property :min_interest_rate, Integer, :index => true
  property :installment_frequency, Enum.send('[]',*INSTALLMENT_FREQUENCIES), :index => true
  property :max_number_of_installments, Integer, :index => true
  property :min_number_of_installments, Integer, :index => true

end
