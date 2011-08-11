class Domain
  include DataMapper::Resource
  
  property :id,   Serial
  property :dmn_guid, String
  property :name, String

  belongs_to :organization

end
