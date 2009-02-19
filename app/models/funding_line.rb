class FundingLine
  include DataMapper::Resource
  before :valid?, :parse_dates
  
  property :id,                  Serial
  property :amount,              Integer
  property :interest_rate,       Integer
  property :purpose,             Text
  property :disbusal_date,       Date  # with these 3 dates and the amount we can draw rough graphs
  property :first_payment_date,  Date
  property :last_payment_date,   Date

  belongs_to :funder
  has n, :loans

  validates_with_method  :disbursal_date,       :method => :disbursed_before_first_payment?
  validates_with_method  :first_payment_date,   :method => :disbursed_before_first_payment?
  validates_with_method  :first_payment_date,   :method => :first_payment_before_last_payment?
  validates_with_method  :last_payment_date,    :method => :first_payment_before_last_payment?
  validates_present :amount, :interest_rate, :disbusal_date, :first_payment_date, :last_payment_date, :funder



  def outstanding_principal_on(date)
    if date < disbusal_date
      return 0
    elsif date >= disbusal_date and date < first_payment_date
      return amount
    elsif date >= first_payment_date and date < last_payment_date
      return amount - (amount.to_f / (last_payment_date - first_payment_date) * (date - first_payment_date)).round
    end
    return 0
  end

  private
  include DateParser  # mixin for the hook "before :valid?, :parse_dates"

  def disbursed_before_first_payment?
    return true if disbursal_date.blank? or (disbursal_date and first_payment_date and disbursal_date <= first_payment_date)
    [false, "First payment date cannot be before the disbursal date"]
  end
  def first_payment_before_last_payment?
    return true if first_payment_date.blank? or (first_payment_date and last_payment_date and first_payment_date <= last_payment_date)
    [false, "Last payment date cannot be before the first payment date"]
  end
end