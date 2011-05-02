class WeeksheetRow
  include DataMapper::Resource
  
  property :id,         Serial
  property :client_id, Integer
  property :client_name, String
  property :client_group_id, Integer
  property :client_group_name, String
  property :loan_id, Integer
  property :loan_amount, Float
  property :disbursal_date, Date
  property :outstanding, Float
  property :principal, Float
  property :installment, Integer
  property :interest, Float
  property :fees, Float


  belongs_to :weeksheet
end


