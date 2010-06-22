class Account
  include DataMapper::Resource

  property :id,                     Serial  
  property :name,                   String
  property :opening_balance,        Integer, :default => 0 
  property :gl_code,                String
  property :parent_id,              String
  belongs_to :account, :model => 'Account', :child_key => [:parent_id]
  belongs_to :account_type
  is :tree, :order => :name

  validates_present :name 
  validates_present :gl_code
  validates_length  :name,     :minimum => 3
  validates_length  :gl_code,  :minimum => 3  
  validates_is_unique :gl_code
  validates_is_number :opening_balance
end
