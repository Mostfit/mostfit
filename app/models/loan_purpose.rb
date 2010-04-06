class LoanPurpose
  include DataMapper::Resource

  property :id, Serial
  property :value, String
  property :code, String, :length => 3

  default_scope(:default).update(:order => [:value])
end
