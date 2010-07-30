class DebitAccountRule
  include DataMapper::Resource
  property :id, Serial
  belongs_to :rule_book
  belongs_to :debit_account, Account
end

