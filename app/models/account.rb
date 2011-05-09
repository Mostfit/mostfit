class Account
  include DataMapper::Resource
  attr_accessor :debit, :credit, :balance, :balance_debit, :balance_credit, :opening_balance_debit, :opening_balance_credit, :branch_edge
  before :save, :convert_blank_to_nil

  property :id,                     Serial  
  property :name,                   String, :index => true
  property :opening_balance,        Integer, :nullable => false, :default => 0
  property :opening_balance_on_date, Date, :nullable => false, :default => Date.today
  property :gl_code,                String, :index => true
  property :parent_id,              Integer, :index => true
  property :account_id,             Integer, :index => true
  property :account_category,       Enum.send('[]', *['', 'Cash', 'Bank']), :default => '', :nullable => true, :index => true
  belongs_to :account, :model => 'Account', :child_key => [:parent_id]
  belongs_to :account_type
  
  property   :branch_id,               Integer, :nullable => true, :index => true
  belongs_to :branch,                  :model => 'Branch', :child_key => [:branch_id]

  has n, :credit_account_rules
  has n, :debit_account_rules
#  has n, :credit_accounts,  RuleBook, :through => :credit_accounts_rules
#  has n, :debit_accounts, RuleBook, :through => :debit_accounts_rules

  has n, :postings
  has n, :journals, :through => :postings
  has n, :account_balances
  has n, :accounting_periods, :through => :account_balances
  
  is :tree, :order => :name
  
  validates_present   :name 
  validates_present   :gl_code
  validates_length    :name,     :minimum => 3
  validates_length    :gl_code,  :minimum => 3  
  validates_is_unique :name, :scope => :branch
  validates_is_unique :gl_code, :scope => :branch
  validates_is_number :opening_balance

  # check if it is a cash account
  def is_cash_account?
    @account_category ? @account_category.eql?('Cash') : false
  end
  
  # check if it is a bank account
  def is_bank_account?
    @account_category ? @account_category.eql?('Bank') : false
  end

  def opening_and_closing_balances_as_of(for_date = Date.today)
    return [nil, nil] if for_date > Date.today
    opening_balance_on_date = opening_balance_as_of for_date
    postings_on_date = postings("journal.date" => for_date).aggregate(:amount.sum)
    closing_balance_on_date = nil
    if postings_on_date.nil?
      closing_balance_on_date = opening_balance_on_date if opening_balance_on_date
    else
      opening_balance_on_date ||= 0.0
      closing_balance_on_date = postings_on_date + opening_balance_on_date
    end
    [opening_balance_on_date, closing_balance_on_date]
  end

  def closing_balance_as_of(for_date = Date.today)
    return nil if for_date > Date.today
    opening_balance_on_date = opening_balance_as_of for_date
    postings_on_date = postings("journal.date" => for_date).aggregate(:amount.sum)
    return nil if opening_balance_on_date.nil? && postings_on_date.nil?
    opening_balance_on_date ||= 0.0; postings_on_date ||= 0.0
    return opening_balance_on_date + postings_on_date
  end
  
  def opening_balance_as_of(for_date = Date.today)
    return nil if for_date > Date.today
    datum_balance = 0.0; datum = nil
    check_past_period = true
    
    if opening_balance_on_date
      # can't have an opening balance before we're open
      return nil if (for_date < opening_balance_on_date)
      period_for_date = AccountingPeriod.get_accounting_period opening_balance_on_date
      if (period_for_date && for_date  < period_for_date.end_date)
        check_past_period = false
        datum_balance = opening_balance ||= 0.0
        datum = opening_balance_on_date
      end
    end

    datum_balance, datum = get_past_period_opening_balance_and_date(for_date) if (check_past_period)

    date_params = {"journal.date.lt" => for_date}
    date_params["journal.date.gte"] = datum if (datum && (datum < for_date))
    balance_from_postings = postings(date_params).aggregate(:amount.sum)
    
    return nil if (datum_balance.nil? && balance_from_postings.nil?)
    datum_balance ||= 0.0; balance_from_postings ||= 0.0
    return datum_balance + balance_from_postings
  end

  # Retreats backward in time to the earliest accounting period that has a balance
  # for us, returns the balance and the date
  def get_past_period_opening_balance_and_date(for_date = Date.today)
    opening_balance, on_date = nil, nil
    period = AccountingPeriod.get_accounting_period for_date
    unless period.nil?
      period_balance = account_balances.first(:accounting_period => period)
      
      if period_balance
        opening_balance = period_balance.opening_balance
        on_date = period.begin_date
      else
        previous_period = period.prev
        unless previous_period.nil?
          previous_date = previous_period.end_date
          # Recurse until we hit an accounting period in the past that has an opening
          # balance for us,
          opening_balance, on_date = get_past_period_opening_balance_and_date(previous_date)
        end
      end
    end
    [opening_balance, on_date]
  end

  def account_earliest_date
    # oops! the opening_balance_as_on date is greater than the earliest posting date!!
    # TODO: Disallow postings before the date an account is first added to the system
    opening_balance_on_date || postings("journal.date.lte" => Date.today).map{|p| p.journal.date}.min || Date.min_date
  end

  def convert_blank_to_nil
    self.attributes.each{|k, v|
      if v.is_a?(String) and v.empty? and self.class.send(k).type==Integer
        self.send("#{k}=", nil)
      end
    }
  end
  
  
  # generate tree form of accounts based on parent relationships.
  # TODO: Not working correctly right now
  def self.tree(branch_id = nil)
    data = {}
    Account.all(:order => [:account_type_id.asc], :parent_id => nil).group_by{|account| account.account_type}.each{|account_type, accounts|
      accounts.each{|account| 
        account.branch_edge = (account.branch_id == branch_id)
      }
      # recurse the tree: climb
      data[account_type] = climb(accounts, branch_id)
      #color branches which contain the specific branch id
      color(data[account_type], branch_id)
      # cut uncolored branches
      #data[account_type] = cut(data[account_type])
    }
    data
  end

  private
  def self.climb(accounts, branch_id)
    # mark branch edges
    accounts.each{|account| account.branch_edge = (account.branch_id == branch_id)}
    #make tree
    accounts.map{|account|
      account.children.length>0 ? [account, climb(account.children, branch_id)] : [account]
    }
  end
  
  def self.color(accounts, branch_id)
    return if accounts.length == 0
    first_account, rest_accounts = accounts[0], accounts[1..-1]||[]
    if first_account.is_a?(Account)      
      accounts[0].branch_edge ||= accounts[1..-1].flatten.map{|x| x.branch_edge}.include?(true)
      color(accounts[1..-1], branch_id)
    else
      color(accounts[0], branch_id)
      color(accounts[1..-1], branch_id)
    end
  end

  def self.cut(accounts)
    return if accounts.length == 0
    first_account, rest_accounts = accounts[0], accounts[1..-1]||[]
    if first_account.is_a?(Account)
      accounts[0].branch_edge ? accounts : []
    else
      cut(first_account)||[] + [cut(rest_accounts)]
    end    
  end
end

