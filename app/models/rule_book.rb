class RuleBook
  include DataMapper::Resource
  ACTIONS = ['principal', 'interest', 'fees', 'disbursement']
  property :id,   Serial
  property :name, String
  property :action, Enum.send('[]',*ACTIONS)

  belongs_to :credit_account, Account
  belongs_to :debit_account,  Account
  belongs_to :branch,         Branch, :nullable => true
  validates_length :name, :min => 3

  def self.get_accounts(obj)
    if obj.class==Payment
      transaction_type = obj.type
#      branch  = obj.loan.client.center.branch 
    elsif obj.class.superclass==Loan
      transaction_type = :disbursement
#     branch  = obj.client.center.branch
    end
    rule = first(:action => transaction_type)
    [rule.credit_account, rule.debit_account]
  end

end
