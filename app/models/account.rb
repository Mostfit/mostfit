class Account
  include DataMapper::Resource
  attr_accessor :debit, :credit, :balance, :balance_debit, :balance_credit, :opening_balance_debit, :opening_balance_credit, :branch_edge
  before :save, :convert_blank_to_nil

  property :id,                     Serial  
  property :name,                   String, :index => true
  property :opening_balance,        Integer, :default => 0 
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
  is :tree, :order => :name
  
  validates_present   :name 
  validates_present   :gl_code
  validates_length    :name,     :minimum => 3
  validates_length    :gl_code,  :minimum => 3  
  validates_is_unique :name, :scope => :branch
  validates_is_unique :gl_code, :scope => :branch
  validates_is_number :opening_balance
  
  def accounts
    
  end

  def is_cash_account?
    @account_category ? @account_category.eql?('Cash') : false
  end
  
  def is_bank_account?
    @account_category ? @account_category.eql?('Bank') : false
  end
  
  def convert_blank_to_nil
    self.attributes.each{|k, v|
      if v.is_a?(String) and v.empty? and self.class.send(k).type==Integer
        self.send("#{k}=", nil)
      end
    }
  end

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

