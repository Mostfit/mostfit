class Account
  include DataMapper::Resource
  before :save, :convert_blank_to_nil

  property :id,                     Serial  
  property :name,                   String, :index => true
  property :opening_balance,        Integer, :default => 0 
  property :opening_balance_on_date, Date, :nullable => false, :default => Date.today
  property :gl_code,                String, :index => true
  property :parent_id,              Integer, :index => true
  property :account_id,             Integer, :index => true

  belongs_to :account, :model => 'Account', :child_key => [:parent_id]
  belongs_to :account_type
  
  property   :branch_id,               Integer, :nullable => true, :index => true
  belongs_to :branch,                  :model => 'Branch', :child_key => [:branch_id]

  has n, :credit_account_rules
  has n, :debit_account_rules
#  has n, :credit_accounts,  RuleBook, :through => :credit_accounts_rules
#  has n, :debit_accounts, RuleBook, :through => :debit_accounts_rules

  has n, :postings
  is :tree, :order => :name
  
  validates_present   :name 
  validates_present   :gl_code
  validates_length    :name,     :minimum => 3
  validates_length    :gl_code,  :minimum => 3  
  validates_is_unique :name
  validates_is_unique :gl_code
  validates_is_number :opening_balance
  
  
  def convert_blank_to_nil
    self.attributes.each{|k, v|
      if v.is_a?(String) and v.empty? and self.class.send(k).type==Integer
        self.send("#{k}=", nil)
      end
    }
  end
  
end

