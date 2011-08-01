class RuleBook
  include DataMapper::Resource
  before :save, :convert_blank_to_nil
  ACTIONS = [
             'principal', 'interest', 'fees', 'disbursement', 'advance_principal', 
             'advance_interest', 'advance_principal_adjusted', 'advance_interest_adjusted', 'journal'
            ]

  property :id,     Serial
  property :name,   String
  property :action, Enum.send('[]',*ACTIONS)
  property :fee_id, Integer, :nullable => true
  property :from_date, Date, :nullable => false, :default => Date.today
  property :to_date, Date, :nullable => false, :default => Date.today+365
  property :created_at, DateTime, :nullable => false, :default => Time.now 
  property :active,          Boolean, :default => true, :nullable => false, :index => true  
  property :created_by_user_id, Integer, :nullable => false
  property :updated_by_user_id, Integer, :nullable => true
  
  has n, :credit_account_rules
  has n, :debit_account_rules
  has n, :credit_accounts, :model => 'Account', :through => :credit_account_rules
  has n, :debit_accounts,  :model => 'Account', :through => :debit_account_rules

  belongs_to :branch,         Branch, :nullable => true
  belongs_to :fee,            Fee, :nullable => true
  belongs_to :journal_type
  belongs_to :created_by, :child_key => [:created_by_user_id], :model => 'User'  
  belongs_to :updated_by, :child_key => [:updated_by_user_id], :model => 'User'  
  
  validates_present      :name
  validates_is_unique    :name, :scope => :branch
  validates_length       :name, :minimum => 3
  validates_with_method  :debit_account,   :method => :credit_account_is_not_same_as_debit_account?
#  validates_with_method  :action_not_chosen_twice_for_particular_branch
  validates_with_method  :percentage_should_be_100
  validates_with_method  :expire_old_rule
  validates_with_method  :rule_date_range_validation
  validates_with_method  :cannot_overlap
  validates_with_method  :fees_selected

  # This function is used to get accounts based on the transaction in the loan system.
  # Right now these transactions can be payments, loans, or array of payments or loans.
  # This function tries to find the rule by matching the transaction type (principal, interest etc)
  # to the rules available and find the most suitable one.
  # If a rule with branch is available that rule is returned. Otherwise global rule is returned.
  # For advance payments (principal and interest) this function would make normal principal and interest accounts. 
  # advance postings only work from EOD voucher. No automatic postings
  def self.get_accounts(obj, amount = nil)
    return false if not Mfi.first.accounting_enabled

    # TODO: Needs a re-write, makes too many assumptions, also locating the appropriate rule still does not take into account
    # the validity of rule by date introduced a while back

    if obj.is_a? Array
      # In case of objects being passed in a set then we give out hashes of credit and debit accounts with values being amount and keys being acocunt
      client = obj.first.client_id > 0 ? obj.first.client : obj.first.loan.client
      branch  = client.center.branch
      date = obj.first.loan.disbursal_date
      credit_accounts, debit_accounts  = {}, {}
      rules = []
      obj.each{|p|
        rule = if p.type == :fees
                 first(:action => p.type, :branch => branch, :fee => p.fee, :active => true) || first(:action => p.type, :branch => nil, :fee => p.fee, :active => true)
               else
                 first(:action => p.type, :branch => branch, :active => true) || first(:action => p.type, :branch => nil, :active => true)
               end
        rule.credit_account_rules.each{|car|
          credit_accounts[rule.id] ||= {}
          credit_accounts[rule.id][car.credit_account.id] ||= 0
          credit_accounts[rule.id][car.credit_account.id] += (p.amount * (car.percentage)/100).round(2)
        }

        rule.debit_account_rules.each{|dar|
          debit_accounts[rule.id] ||= {}
          debit_accounts[rule.id][dar.debit_account.id] ||= 0
          debit_accounts[rule.id][dar.debit_account.id] += (p.amount * (dar.percentage)/100).round(2)
        }
        rules.push(rule)
      }
      return [credit_accounts, debit_accounts, rules]
    end

    if obj.is_a? Payment
      transaction_type = obj.type
      client = obj.client_id > 0 ? obj.client : obj.loan.client
      branch  = client.center.branch
      fee     = obj.fee
      date = obj.received_on
    elsif obj.is_a? Loan
      transaction_type = :disbursement
      branch  = obj.client.center.branch
      date = obj.disbursal_date
    end

    if rule = first(:action => transaction_type, :branch => branch, :fee => fee, :active => true)
    elsif rule = first(:action => transaction_type, :branch => nil, :fee => nil, :active => true)
    elsif rule = first(:action => transaction_type, :branch => nil, :fee => fee, :active => true)
    elsif rule = first(:action => transaction_type, :branch => branch, :fee => nil, :active => true)
    else
      raise "NoRuleFoundError"
    end

    credit_accounts, debit_accounts  = {}, {}
    rule.credit_account_rules.each{|car|
      credit_accounts[rule.id] ||= {}
      credit_accounts[rule.id][car.credit_account.id] ||= 0
      credit_accounts[rule.id][car.credit_account.id] += (obj.amount * (car.percentage)/100).round(2)
    }

    rule.debit_account_rules.each{|dar|        
      debit_accounts[rule.id] ||= {}
      debit_accounts[rule.id][dar.debit_account.id] ||= 0
      debit_accounts[rule.id][dar.debit_account.id] += (obj.amount * (dar.percentage)/100).round(2)
    }    
    [credit_accounts, debit_accounts, rule]
  end
  
  # presentage split between credit and debit accounts should be 100% (each)
  def percentage_should_be_100
    return [false, "Credit account split is not 100%"] if credit_account_rules.map{|a| a.percentage}.inject(0){|s,x| s+=x||0}!=100
    return [false, "Debit account split is not 100%"]  if debit_account_rules.map{|a| a.percentage}.inject(0){|s,x| s+=x||0}!=100
    return true
  end

  def fees_selected
    return [false, "fee must be selected for fee action"] if action == 'fees' and fee_id == nil
    return true
  end

  # credit and debit accounts cannot be exactly same
  def credit_account_is_not_same_as_debit_account?
    if credit_account_rules.length > 0 and debit_account_rules.length > 0 and (credit_account_rules.map{|x| x.credit_account_id} == debit_account_rules.map{|x| x.debit_account_id})
      [false, "Credit and Debit account cannot be same"]
    elsif credit_accounts.length > 0 and debit_accounts.length > 0 and (credit_accounts.map{|x| x.account_id} == debit_accounts.map{|x| x.account_id})
      [false, "Credit and Debit account cannot be same"]
    else
      return true 
    end
  end

  def journals(date)
    ids = (Posting.all("journal.date" => date,
                       :account => self.debit_accounts).aggregate(:journal_id) & Posting.all("journal.date" => date,
                                                                                             :account => self.credit_accounts).aggregate(:journal_id))
    if ids.length > 0
      Journal.all(:id => ids)
    else
      nil
    end
  end

  def convert_blank_to_nil
    self.attributes.each{|k, v|
      if v.is_a?(String) and v.empty? and self.class.send(k).type==Integer
        self.send("#{k}=", nil)
      end
    }
  end
  
  # This function makes sure duplicate active reules are not created for the same action and branch
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

  # this function will work  if same rule is been created for same branch 
  #  it will deactivate old rule after creation of new rule for same action like disbursment, interest, fee or principal 

  def cannot_overlap
    unless self.new?
      @changed_attr_with_original_val = self.original_attributes.map{|k,v| {k.name => (k.lazy? ? obj.send(k.name) : v)}}.inject({}){|s,x| s+=x}
      return true unless @changed_attr_with_original_val.keys.include?(:from_date) or @changed_attr_with_original_val.keys.include?(:to_date)
    end
    
    overlaps = RuleBook.all(:branch_id => branch_id, :action => action, :journal_type_id => self.journal_type_id, :fee_id => fee_id, :to_date.lte => self.to_date, :to_date.gte => self.from_date)
    overlaps = RuleBook.all(:branch_id => branch_id, :action => action, :journal_type_id => self.journal_type_id, :fee_id => fee_id, :from_date.gte => self.from_date, :from_date.lte => self.to_date) if overlaps.empty?

    if self.new?
      return true if overlaps.empty?
    else
      return true if overlaps.count <= 1 #because it certainly gonna check with itself so overlaps inlcudes self
    end
    return [false, "Rule overlaps with an existing rule #{overlaps.first.name}"]
  end

  def expire_old_rule
    if self.new?
      RuleBook.all.each do |rule|
        if rule.action == self.action and rule.branch_id == self.branch_id and rule.fee_id == self.fee_id and rule.to_date >= self.from_date and rule.active == true
          rule.to_date = self.from_date-1
          rule.active =  false
          rule.save
          return true 
        end
      end
    end
    return true
  end

  # will verify that from date is always less than to date 
  def rule_date_range_validation
    if self and self.from_date > self.to_date
      return [false,"from_date should be less than to_date"]
    else
      return true
    end
  end
end
