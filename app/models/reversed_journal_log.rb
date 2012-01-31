class ReversedJournalLog
  include DataMapper::Resource
  
  property :id, Serial
  property :journal_id, Integer, :nullable => false
  property :created_at, DateTime

end
