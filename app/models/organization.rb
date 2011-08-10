class Organization
  include DataMapper::Resource
  
  property :id,   Serial
  property :guid, String
  property :name, String
  
  has n, :domains
  
end
