class InsuranceCompany
  include DataMapper::Resource
  
  property :id, Serial
  property :name, Text, :length => 100

  has n, :insurance_policies

end
