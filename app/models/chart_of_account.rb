class ChartOfAccount
  include DataMapper::Resource

  property :id,              Serial  
  property :name,            String
  property :gl_code,         String
  property :parent_gl_code,  String
  property :account_type,    Enum.send('[]', *[:assets, :expenditure, :liabilities, :income]), :nullable => false, :index => true
  #belongs_to :ChartOfAccount, :model => 'Account', :child_key => 'parent_id'
end




#ChartOfAccount.transaction do |t|
#  begin
#    t1 = AccountTransaction.create()
#    t2 = AccountTransaction.create()
#  rescue
#    t.rollback
# end
#end

#DataMapper.auto_migrate!

#assets                 = Account.new(:name => "ASSETS", :code => "10000")
#cash_and_bank_balances = Account.new(:name => "Cash and bank balances", :code => "11000", :parent_id => assets.id)
#petty_cash_account     = Account.new(:name => "Petty Cash Accounts", :code => "11100", :parent_id => cash_and_bank_balances.id)
#cash_1                 = Account.new(:name => "Cash 1", :code => "11101", :parent_id => petty_cash_account.id)
#cash_2                 = Account.new(:name => "Cash 2", :code => "11102", :parent_id => petty_cash_account.id)
