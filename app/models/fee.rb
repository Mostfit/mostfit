class Fee
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String
  property :percentage, Float
  property :amount, Integer
  property :min_amount, Integer
  property :max_amount, Integer
  property :steps, Text
  property :description, Text
end
