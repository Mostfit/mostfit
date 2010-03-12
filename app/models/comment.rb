class Comment
  include DataMapper::Resource
  
  property :id, Serial
  
  property :text,           Text
  property :parent_model,   String
  property :parent_id,      Integer
  property :created_at,     DateTime
  
  belongs_to :user

end
