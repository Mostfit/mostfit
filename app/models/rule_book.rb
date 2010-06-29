class RuleBook
  include DataMapper::Resource
  before :save, :convert_blank_to_nil
  ACTIONS = ['principal', 'interest', 'fees', 'disbursement']

  property :id,     Serial
  property :name,   String
  property :action, Enum.send('[]',*ACTIONS)

  belongs_to :credit_account, Account
  belongs_to :debit_account,  Account
  belongs_to :branch,         Branch, :nullable => true

  validates_present      :name
  validates_is_unique    :name
  validates_length       :name,     :minimum => 3
  validates_with_method  :debit_account,   :method => :credit_account_is_not_same_as_debit_account?
  validates_with_method  :action_not_chosen_twice_for_particular_branch
  
  def self.get_accounts(obj)
    return false if $globals and $globals[:mfi_details] and not $globals[:mfi_details][:accounting_enabled]
    if obj.class==Payment
      transaction_type = obj.type
      branch  = obj.loan.client.center.branch 
    elsif obj.class.superclass==Loan
      transaction_type = :disbursement
      branch  = obj.client.center.branch
    end
    if rule = first(:action => transaction_type, :branch => branch)
    elsif rule = first(:action => transaction_type, :branch => nil)
    else
      raise NoRuleFoundError
    end
    [rule.credit_account, rule.debit_account]
  end
  
  def credit_account_is_not_same_as_debit_account?
    return true if credit_account_id != debit_account_id
    [false, "Credit and Debit account cannot be same"]
  end

  def convert_blank_to_nil
    self.attributes.each{|k, v|
      if v.is_a?(String) and v.empty? and self.class.send(k).type==Integer
        self.send("#{k}=", nil)
      end
    }
  end

  def action_not_chosen_twice_for_particular_branch
    return true if RuleBook.first(:action => action, :branch_id => branch_id) == nil
    [false, "This action has already been chosen for this branch"]
  end
end
