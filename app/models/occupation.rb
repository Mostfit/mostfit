class Occupation
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :code, String, :length => 3

  has n, :clients
  has n, :loans
  default_scope(:default).update(:order => [:name])
end
