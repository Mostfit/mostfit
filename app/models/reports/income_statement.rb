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
        amount = account.change_closing_over_opening_balance_for_period accounting_period.begin_date
        amount ||= 0.0
        accounts_and_amounts[account] = amount 
      end
      data[income_head] = accounts_and_amounts
    end
    data
  # TODO: Display side-by-side for chosen period and previous period
  end

end
