# All accounting actions happen during a particular accounting period
# Only one accounting period can be in force at any time
# Any accounts in existence during an accounting period can have an opening balance other than zero assigned to them (exactly once) 
# At the end of an accounting period, "books" must be "closed" and balances brought forward to the beginning of the next accounting period as the opening balances for the new period
# Ideally, an administrator should "close" an accounting period and the system should disallow any accounting entries under the period once closed

class AccountingPeriod
  include DataMapper::Resource
  
  property :id, Serial
  property :begin_date, Date, :nullable => false, :default => Date.today
  property :end_date, Date, :nullable => false, :default => Date.today+365
  property :created_at, DateTime, :nullable => false, :default => Time.now 
  property :created_by_user_id, Integer, :nullable => false

  belongs_to :created_by, :child_key => [:created_by_user_id], :model => 'User'

  def duration
    (end_date - begin_date).to_i + 1
  end
end
