class InsuranceProduct
  include DataMapper::Resource
  
  property :id, Serial
  property :name, Text, :length => 100
 
  belongs_to :insurance_company 
  has n, :insurance_policies
  has n, :fees, :through => Resource

end
