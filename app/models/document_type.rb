class DocumentType
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String
  
  has n, :documents

end
