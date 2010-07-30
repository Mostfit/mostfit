class CreditAccountRule
  include DataMapper::Resource
  property :id, Serial
  belongs_to :rule_book
  belongs_to :credit_account, Account
end
