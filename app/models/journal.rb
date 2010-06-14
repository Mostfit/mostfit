class Journal
  include DataMapper::Resource
  
  property :id,             Serial
  property :comment,        String 
  property :transaction_id, Integer
  property :creation_date,  DateTime

  belongs_to :batch
  has n, :postings
end
