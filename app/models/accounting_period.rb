# All accounting actions happen during a particular accounting period
# Only one accounting period can be in force at any time
# Any accounts in existence during an accounting period can have an opening balance other than zero assigned to them (exactly once) 
# At the end of an accounting period, "books" must be "closed" and balances brought forward to the beginning of the next accounting period as the opening balances for the new period
# Ideally, an administrator should "close" an accounting period and the system should disallow any accounting entries under the period once closed


# Are these supposed to be system wide? I saw they (optionally) belong_to an Organization but when I look
# at validation methods like #closing_done_sequentially it seems to validate against AccountingPeriod.all,
# without any mention of the related organization.
#
# Also creating a new accounting period when no others exist seems to be impossible as far as I can tell.
# The validation done in #closing_done_sequentially seems to always fail if no other records exist, even
# if we're not trying to close the period.
#

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
  
  belongs_to :organization
  property :organization_id, Integer, :nullable => true

  # Let's make sure closed is never nil to avoid confusing error messages from #closing_done_sequentially
  # which may bork if closed is nil instead of false
  validates_present :closed

  validates_with_method :cannot_overlap
  validates_with_method :closing_done_sequentially
  validates_with_method :all_account_balances_are_verified_before_closing_accounting_period

  # This method is used to compare/sort AccountingPeriods by begin_date
  def <=>(other)
    return (end_date <=> other.begin_date) if other.respond_to?(:begin_date) && other.begin_date
    return 0
  end

  # The total duration of the period in days
  def duration
    (end_date - begin_date).to_i + 1
  end

  def is_first_period?
    begin_date == self.model.aggregate(:begin_date).min
  end

  def cannot_overlap
    @changed_attr_with_original_val = self.original_attributes.map{|k,v| {k.name => (k.lazy? ? obj.send(k.name) : v)}}.inject({}){|s,x| s+=x}
    return true if @changed_attr_with_original_val.keys.size == 1 and @changed_attr_with_original_val.keys.include?(:closed)
    overlaps = AccountingPeriod.all(:end_date.lte => end_date, :end_date.gt => begin_date)
    overlaps = AccountingPeriod.all(:begin_date.gte => begin_date, :begin_date.lt => end_date) if overlaps.empty?
    return true if overlaps.empty?
    return [false, "Your accounting period overlaps with other accounting periods"]
  end

  # This returns true if the current record is the very first of the open accounting periods
  # and we've set the closed attribute to true (i.e. we're trying to close the first remaining
  # open period) OR if we are the last of the closed periods and we've set closed to false
  # (i.e. we're reopening the last closed period)
  #
  # Right now this also causes validations to fail if we're creating a new accounting period
  # from scratch which should probably be fixed.
  #
  def closing_done_sequentially
    # This may be slightly faster if we move the first conditional before the second database query
    closedAP = AccountingPeriod.all(:closed => true, :order => [:begin_date.asc])
    openAP = AccountingPeriod.all(:closed => false, :order => [:begin_date.asc])
    return true if self.id == openAP.first.id and self.closed == true
    return true if self.id == closedAP.last.id and self.closed == false
    return [false, "This Cannot be closed"]
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

  def get_last_accounting_period_before(date = Date.today)
    AccountingPeriod.all(:to_date.lt => date, :order_by => [:to_date]).last
  end


  def self.get_current_accounting_period!
    get_accounting_period || get_last_accounting_period_before
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

  def all_account_balances_are_verified_before_closing_accounting_period
    return true unless self.closed
    AccountBalance.all(:accounting_period => self).each do |ab|
      return [false,"#{ab.account.name} has not been verified for this period"] unless ab.verified?
    end
    return true
  end
end
