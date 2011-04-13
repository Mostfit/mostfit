class LoanPurpose
  include DataMapper::Resource

  property :id, Serial
  property :value, String
  property :code, String, :length => 3

  validates_is_unique :value
  validates_is_unique :code
  default_scope(:default).update(:order => [:value])
end
