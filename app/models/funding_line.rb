class FundingLine
  include DataMapper::Resource
  extend Reporting::FundingLineReports

  before :valid?, :parse_dates

  attr_accessor :interest_percentage  # set to true to disable history writing by this object

  property :id,                  Serial
  property :amount,              Integer, :index => true
  property :interest_rate,       Float, :index => true
  property :purpose,             Text
  property :disbursal_date,      Date  # with these 3 dates and the amount we can draw rough graphs
  property :first_payment_date,  Date
  property :last_payment_date,   Date
  property :closed_on,           Date
  property :closing_comment,     Text

  belongs_to :funder
  has n, :loans
  validates_with_method  :disbursal_date,       :method => :disbursed_before_first_payment?
  validates_with_method  :first_payment_date,   :method => :disbursed_before_first_payment?
  validates_with_method  :first_payment_date,   :method => :first_payment_before_last_payment?
  validates_with_method  :last_payment_date,    :method => :first_payment_before_last_payment?
  validates_present :amount, :interest_rate, :disbursal_date, :first_payment_date, :last_payment_date, :funder

  def self.from_csv(row, headers)
    funder = Funder.create(:name => row[headers[:funder_name]])
    obj = new(:funder_id => funder.id, :amount => row[headers[:amount]], :interest_rate => row[headers[:interest]],
              :disbursal_date => Date.parse(row[headers[:disbursal_date]]), :first_payment_date => Date.parse(row[headers[:first_payment_date]]),
              :last_payment_date => Date.parse(row[headers[:last_payment_date]]))
    [obj.save, obj]
  end

  def status
    if :closed_on
      status = :closed
    else
      status = :open
    end
    status
  end

  def name
    "#{funder.name} #{amount}@#{interest_rate}"
  end

  def outstanding_principal_on(date)
    if date < disbursal_date
      return 0
    elsif date >= disbursal_date and date < first_payment_date
      return amount
    elsif date >= first_payment_date and date < last_payment_date
      return amount - (amount.to_f / (last_payment_date - first_payment_date) * (date - first_payment_date)).round
    end
    return 0
  end

  def interest_percentage  # code dupe with the Loan
    return nil if interest_rate.blank?
    format("%.2f", interest_rate * 100)
  end
  def interest_percentage= (percentage)
    p 'wqwwwwwwwwwwwwwwwwwwwwww'
    p percentage
    self.interest_rate = percentage.to_f/100
    p interest_rate
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
