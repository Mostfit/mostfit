class Posting
  include DataMapper::Resource
  
  property :id, Serial
  property :amount, Float
  
  belongs_to :journal
  belongs_to :account

end
