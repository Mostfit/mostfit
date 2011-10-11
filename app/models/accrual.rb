class Accrual
  include DataMapper::Resource

  # Accrual records revenues or expenses accrued on particular dates
  #
  # For e.g., interest income accrued on loans made, interest expense payable on
  # deposits, etc. Accrual does not represent an actual exchange of money and is
  # therefore not treated the same as transactions

  ACCRUE_INTEREST_RECEIVABLE = :interest_receivable; ACCRUE_INTEREST_PAYABLE = :interest_payable
  ACCRUAL_TYPES = [ ACCRUE_INTEREST_RECEIVABLE, ACCRUE_INTEREST_PAYABLE ]

  # TODO: Move these constants to the correct location
  DEFAULT_CURRENCY = :INR
  CURRENCIES = [DEFAULT_CURRENCY]
  
  property :id,                 Serial
  property :amount,             Float, :nullable => false
  property :currency,           Enum.send('[]', *CURRENCIES)
  property :accrual_type,       Enum.send('[]', *ACCRUAL_TYPES)
  property :accrue_overdue_amount, Boolean, :nullable => false, :default => false
  property :is_penalty,         Boolean, :nullable => false, :default => false
  property :accrue_from_date,   Date, :nullable => false
  property :accrue_till_date,   Date, :nullable => false
  property :accrue_on_date,     Date, :nullable => false
  property :created_at,         DateTime, :nullable => false, :default => DateTime.now
  property :created_by_user_id, Integer, :nullable => false

  belongs_to :loan, :nullable => true
  belongs_to :created_by, :child_key => [:created_by_user_id], :model => 'User'

  ACCRUE_SIMPLE_INTEREST_RECEIVABLE = { :accrual_type => ACCRUE_INTEREST_RECEIVABLE, :is_penalty => false }

  def Accrual.interest_receivable_accrued_on_loan(on_loan, as_of_date = Date.today, by_currency = DEFAULT_CURRENCY)
    accruals = all(:loan => on_loan, :accrual_type => ACCRUE_INTEREST_RECEIVABLE, :accrue_on_date.lte => as_of_date, :is_penalty => false, :currency => by_currency)
    interest_accrued = 0
    accruals.inject(interest_accrued) {|interest_accrued, accrual| interest_accrued += accrual.amount }
    [interest_accrued, by_currency]
  end

  def Accrual.latest_simple_interest_receivable_accrued(on_loan)
    query = ACCRUE_SIMPLE_INTEREST_RECEIVABLE.merge(:loan => on_loan, :order => [:accrue_on_date.desc])
    last(query)
  end

  def Accrual.accrue_simple_interest_receivable(on_loan, by_user, for_amount, from_date, till_date = Date.today, accrue_on = till_date, accrue_overdue_amount = false, in_currency = DEFAULT_CURRENCY)
    most_recent_accrual = latest_simple_interest_receivable_accrued(on_loan)
    accrue_from_date = from_date
    accrue_from_date = most_recent_accrual.accrue_till_date if (most_recent_accrual and from_date < most_recent_accrual.accrue_till_date)
    accrue_new_interest_receivable(on_loan, by_user, for_amount, accrue_from_date, till_date, accrue_on, accrue_overdue_amount, false, in_currency)
  end

  private

  def Accrual.accrue_new_interest_receivable(on_loan, by_user, for_amount, from_date, till_date, accrue_on = till_date, accrue_overdue_amount = false, as_penalty = false, in_currency = DEFAULT_CURRENCY)
    create(:loan => on_loan, :created_by => by_user, :amount => for_amount, :currency => in_currency, :accrual_type => ACCRUE_INTEREST_RECEIVABLE, :accrue_overdue_amount => accrue_overdue_amount, :is_penalty => as_penalty, :accrue_from_date => from_date, :accrue_till_date => till_date, :accrue_on_date => accrue_on)
  end

end
