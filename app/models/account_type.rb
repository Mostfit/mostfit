class AccountType
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String
  property :code, String 
  
 has n, :accounts
end
