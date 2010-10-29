class InsuranceCompany
  include DataMapper::Resource
  
  property :id, Serial
  property :name, Text, :length => 100

  has n, :insurance_products
  validates_is_unique :name
  default_scope(:default).update(:order => [:name])
end
