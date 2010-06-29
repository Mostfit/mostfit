class AccountType
  include DataMapper::Resource
  
  property :id,   Serial
  property :name, String, :index => true 
  property :code, String, :index => true  
  
  has n, :accounts
  validates_present :name
  validates_present :code
  validates_length :name,   :minimum => 3
  validates_length :code,   :minimum => 3
  validates_is_unique :code
end
