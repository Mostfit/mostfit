class RuleBook
  include DataMapper::Resource
  property :id,   Serial
  property :name, String
  property :action, Enum[:principal, :interest, :fees, :disbursement]

  belongs_to :credit_account, Account
  belongs_to :debit_account,  Account
  belongs_to :branch,         Branch 

  def self.get_accounts(obj)
    if obj.class==Payment
      transaction_type = obj.type
      branch  = obj.loan.client.center.branch
    else
      transaction_type = :disbursement
      branch  = obj.client.center.branch
    end
    rule = first(:action => transaction_type, :branch => branch)
    [rule.debit_account, rule.credit_account]
  end

end
