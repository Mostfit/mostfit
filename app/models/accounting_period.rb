# All accounting actions happen during a particular accounting period
# Only one accounting period can be in force at any time
# Any accounts in existence during an accounting period can have an opening balance other than zero assigned to them (exactly once) 
# At the end of an accounting period, "books" must be "closed" and balances brought forward to the beginning of the next accounting period as the opening balances for the new period
# Ideally, an administrator should "close" an accounting period and the system should disallow any accounting entries under the period once closed

class AccountingPeriod
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String
  property :begin_date, Date, :nullable => false, :default => Date.today
  property :end_date, Date, :nullable => false, :default => Date.today+365
  property :created_at, DateTime, :nullable => false, :default => Time.now 


  has n, :account_balances
  has n, :accounts, :through => :account_balances

  validates_with_method :cannot_overlap

  def duration
    (end_date - begin_date).to_i + 1
  end

  def is_first_period?
    begin_date == self.model.aggregate(:begin_date).min
  end

  def cannot_overlap
    overlaps = AccountingPeriod.all(:end_date.lte => end_date, :end_date.gt => begin_date) or AccountingPeriod.all(:begin_date.gte => begin_date, :begin_date.lt => end_date)
    return true if overlaps.empty?
    return [false, "Your accounting period overlaps with other accounting periods"]
  end

end
