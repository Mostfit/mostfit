class DebitAccountRule
  include DataMapper::Resource
  property :id, Serial
  property :rule_book_id, Integer
  property :account_id,   Integer
  property :percentage,   Float, :nullable => false, :default => 100

  belongs_to :rule_book
  belongs_to :debit_account, Account
end

