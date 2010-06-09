class Accounting
  include DataMapper::Resource
  TYPES = [:none, :assets, :expenditure, :liabilities, :income ]
  property :id,                Serial  
  property :name,              String
  property :gl_code,           String
  property :parent_account_id, String
  property :account_type,      Enum.send('[]', *TYPES), :nullable => false , :default => :none, :index => true

  #belongs_to :account, :model => 'Account', :child_key => 'parent_id'

def self.account_types
 TYPES
end 

end

class AccountTransaction
  include DataMapper::Resource
  property :id,               Serial  
  property :transaction_type, Enum[:debit, :credit]
  property :amount,           Float
  property :comment,          String
  property :created_at,       DateTime
  belongs_to :accounting
  
end

AccountingTransaction.transaction do |t|
 begin
   t1 = AccountTransaction.create()
   t2 = AccountTransaction.create()
 rescue
   t.rollback
end
end



