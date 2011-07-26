class LoanPurpose
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :code, String, :length => 3
  property :parent_id, Integer, :default => 0

  validates_present :name
  validates_is_unique :name
  validates_is_unique :code
  
  has n, :loans
  has n, :purposes, self, :child_key => [:parent_id]
  
  default_scope(:default).update(:order => [:name])
end
