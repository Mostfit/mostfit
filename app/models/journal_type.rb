class JournalType 

  include DataMapper::Resource

  property :id,         Serial
  property :name,       String, :default => "Payment"  
  property :created_at, DateTime
  has n, :journal
end
  
# if JournalType.all.empty?
#   DEFAULT_JOURNAL_TYPES.each do |x|
#     JournalType.create(:name => x)
#   end

      

