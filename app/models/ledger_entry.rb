class LedgerEntry
  include DataMapper::Resource
  
  property :id, Serial
  property :ledger_name, String
  property :transaction, Enum[:debit, :credit]
  property :date, Date
  property :comment, Text
  property :amount, Float
  property :created_at, DateTime
  property :updated_at, DateTime

end
