# All accounting actions happen during a particular accounting period
# Only one accounting period can be in force at any time
# Any accounts in existence during an accounting period can have an opening balance other than zero assigned to them (exactly once) 
# At the end of an accounting period, "books" must be "closed" and balances brought forward to the beginning of the next accounting period as the opening balances for the new period
# Ideally, an administrator should "close" an accounting period and the system should disallow any accounting entries under the period once closed

class AccountingPeriod
  include DataMapper::Resource
  
  property :id,         Serial
  property :name,       String
  property :begin_date, Date, :nullable => false, :default => Date.today
  property :end_date,   Date, :nullable => false, :default => Date.today+365
  property :closed,     Boolean, :nullable => false, :default => false
  property :created_at, DateTime, :nullable => false, :default => Time.now

  has n, :account_balances
  has n, :accounts, :through => :account_balances

  validates_with_method :cannot_overlap

  def <=>(other)
    return (end_date <=> other.begin_date) if other.respond_to?(:begin_date) && other.begin_date
    return 0
  end

  def duration
    (end_date - begin_date).to_i + 1
  end

  def is_first_period?
    begin_date == self.model.aggregate(:begin_date).min
  end

  def cannot_overlap
    overlaps = AccountingPeriod.all(:end_date.lte => end_date, :end_date.lgt => begin_date)
    overlaps = AccountingPeriod.all(:begin_date.gte => begin_date, :begin_date.lt => end_date) if overlaps.empty?
    return true if overlaps.empty?
    return [false, "Your accounting period overlaps with other accounting periods"]
  end

=begin
  def dates_in_order
    compare_dates = begin_date <=> end_date
    return true if compare_dates < 0
    return [false, "Begin date must precede end date"]
  end
=end

  def AccountingPeriod.get_accounting_period(for_date = Date.today)
    AccountingPeriod.first(:begin_date.lte => for_date, :end_date.gte => for_date)
  end
  
  def AccountingPeriod.get_current_accounting_period
    get_accounting_period
  end

  def AccountingPeriod.get_earliest_period; AccountingPeriod.all.sort.first; end
  def is_earliest_period?; self == AccountingPeriod.get_earliest_period; end

  def prev
    all_periods = AccountingPeriod.all.sort
    return nil if self == all_periods.first
    idx = all_periods.index(self)
    all_periods[idx - 1]
  end

  def next
    all_periods = AccountingPeriod.all.sort
    return nil if self == all_periods.last
    idx = all_periods.index(self)
    all_periods[idx + 1]
  end

  def get_previous_periods
    AccountingPeriod.get_all_previous_periods(begin_date)
  end

  # Returns the accounting periods preceding the one that was in effect for the given date
  def AccountingPeriod.get_all_previous_periods(for_date = Date.today)
    return nil unless AccountingPeriod.first_period
    return nil if for_date <= AccountingPeriod.first_period.end_date
    all_periods = AccountingPeriod.all.sort
    return all_periods if for_date > AccountingPeriod.last_period.end_date
    period_on_date = AccountingPeriod.get_accounting_period(for_date)
    idx = all_periods.index(period_on_date)
    idx ? all_periods.shift(idx) : nil
  end
  
  def AccountingPeriod.last_period
    AccountingPeriod.all.sort.last
  end

  def AccountingPeriod.first_period
    AccountingPeriod.all.sort.first
  end

  def to_s
    "Accounting period #{name} beginning #{begin_date.strftime("%d-%B-%Y")} through #{end_date.strftime("%d-%B-%Y")}"
  end

end
