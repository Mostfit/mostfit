class Posting
  include DataMapper::Resource
  
  property :id, Serial
  property :amount, Float, :index => true   
  belongs_to :journal
  belongs_to :account
  belongs_to :currency


end

