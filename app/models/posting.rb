class Posting
  include DataMapper::Resource
  
  property :id,           Serial
  property :amount,       Float,   :index => true   
  property :journal_id,   Integer, :index => true  
  property :account_id,   Integer, :index => true  
  property :currency_id,  Integer, :index => true  
  belongs_to :journal
  belongs_to :account
  belongs_to :currency
end

