class RuleBook
  include DataMapper::Resource
  before :save, :convert_blank_to_nil
  ACTIONS = ['principal', 'interest', 'fees', 'disbursement']

  property :id,     Serial
  property :name,   String
  property :action, Enum.send('[]',*ACTIONS)
  property :fee_id, Integer, :nullable => true

  has n, :credit_account_rules
  has n, :debit_account_rules
  has n, :credit_accounts, :model => 'Account', :through => :credit_account_rules
  has n, :debit_accounts,  :model => 'Account', :through => :debit_account_rules

  belongs_to :branch,         Branch, :nullable => true
  belongs_to :fee,            Fee, :nullable => true

  validates_present      :name
  validates_is_unique    :name
  validates_length       :name,     :minimum => 3
  validates_with_method  :debit_account,   :method => :credit_account_is_not_same_as_debit_account?
  validates_with_method  :action_not_chosen_twice_for_particular_branch
  validates_with_method  :percentage_should_be_100
  
  def self.get_accounts(obj)
    return false if ($globals and $globals[:mfi_details] and not $globals[:mfi_details][:accounting_enabled])
    if obj.class==Payment
      transaction_type = obj.type
      client = obj.client_id > 0 ? obj.client : obj.loan.client
      branch  = client.center.branch
      fee     = obj.fee
      #TODO:hack alert! Write it better
    elsif obj.class==Loan or obj.class.superclass==Loan or obj.class.superclass.superclass==Loan
      transaction_type = :disbursement
      branch  = obj.client.center.branch
    elsif obj.class==Array
      # In case of objects being passed in a set then we give out hashes of credit and debit accounts with values being amount and keys being acocunt
      client = obj.first.client_id > 0 ? obj.first.client : obj.first.loan.client
      branch  = client.center.branch      
      credit_accounts, debit_accounts  = {}, {}
      obj.each{|p|  
        rule = if p.type==:fees
                 first(:action => p.type, :branch => branch, :fee => p.fee) || first(:action => p.type, :branch => nil, :fee => p.fee)
               else
                 first(:action => p.type, :branch => branch) || first(:action => p.type, :branch => nil)
               end
        rule.credit_account_rules.each{|car|
          credit_accounts[car.credit_account] ||= 0
          credit_accounts[car.credit_account] += (p.amount * (car.percentage)/100)
        }

        rule.debit_account_rules.each{|dar|
          debit_accounts[dar.debit_account] ||= 0
          debit_accounts[dar.debit_account] += (p.amount * (dar.percentage)/100)
        }
      }
      return [credit_accounts, debit_accounts]
    end
    
    if rule = first(:action => transaction_type, :branch => branch, :fee => fee)
    elsif rule = first(:action => transaction_type, :branch => nil, :fee => nil)
    elsif rule = first(:action => transaction_type, :branch => nil, :fee => fee)
    elsif rule = first(:action => transaction_type, :branch => branch, :fee => nil)
    else
      raise "NoRuleFoundError"
    end

    credit_accounts, debit_accounts  = {}, {}
    rule.credit_account_rules.each{|car|
      credit_accounts[car.credit_account] ||= 0
      credit_accounts[car.credit_account] += (obj.amount * (car.percentage)/100)
    }

    rule.debit_account_rules.each{|dar|        
      debit_accounts[dar.debit_account] ||= 0
      debit_accounts[dar.debit_account] += (obj.amount * (dar.percentage)/100)
    }    
    [credit_accounts, debit_accounts]
  end
  
  def percentage_should_be_100
    return [false, "Credit account split is not 100%"] if credit_account_rules.map{|a| a.percentage}.inject(0){|s,x| s+=x||0}!=100
    return [false, "Debit account split is not 100%"]  if debit_account_rules.map{|a| a.percentage}.inject(0){|s,x| s+=x||0}!=100
    return true
  end

  def credit_account_is_not_same_as_debit_account?
    return true if (credit_accounts.map{|x| x.id} & debit_accounts.map{|x| x.id}).length==0
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
    if self.fee and self.new?
      return [false, "Fee action has already been chosen for this branch"] if RuleBook.first(:fee => fee, :action => action, :branch_id => branch_id)
    elsif self.fee and not self.new?
      return [false, "Fee action has already been chosen for this branch"] if RuleBook.first(:fee => fee, :action => action, :branch_id => branch_id, :id.not => self.id)
    else
      return [false, "Action has already been chosen for this branch"] if RuleBook.first(:action => action, :branch_id => branch_id, :id.not => self.id)
    end
    return true 
  end
end
