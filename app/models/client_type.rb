class ClientType
  include DataMapper::Resource
  
  property :id, Serial

  property :type, String

  has n, :fees


end
