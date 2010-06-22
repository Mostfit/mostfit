class Journal
  include DataMapper::Resource
  
  property :id,             Serial
  property :comment,        String 
  property :transaction_id, Integer
  property :created_at,     DateTime
  property :batch_id,       Integer, :nullable => true

  belongs_to :batch
  has n, :postings
end
