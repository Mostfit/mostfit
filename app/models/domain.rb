class Domain
  include DataMapper::Resource
  
  property :id,   Serial
  property :domain_guid, String
  property :name, String

  belongs_to :organization

end
