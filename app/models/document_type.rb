class DocumentType
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String, :length => 100
  
  has n, :documents
  validates_is_unique :name
  
  default_scope(:default).update(:order => [:name])
end
