class IncomeStatement < Report

  attr_accessor :period, :branch_id

  def initialize(params, dates, user)
    @period = params && params[:period] ? AccountingPeriod.get(params[:period]) : nil
    get_parameters(params, user)
  end
  
  def name
    "Income statement"
  end
  
  def self.name
    "Income Statement"
  end

  def generate
    data = {}
    accounting_period = AccountingPeriod.get(period) if period
    return data unless accounting_period
    INCOME_HEADS.each do |income_head|
      accounts_and_amounts = {}
      Account.all(:income_head => income_head, :branch_id => branch_id).each do |account|
        on_date = accounting_period.end_date > Date.today ? Date.today : accounting_period.end_date
        amount = account.closing_balance_as_of on_date
        amount ||= 0.0
        accounts_and_amounts[account] = amount 
      end
      data[income_head] = accounts_and_amounts
    end
    p data
    data
  # TODO: Display side-by-side for chosen period and previous period
  end

end
