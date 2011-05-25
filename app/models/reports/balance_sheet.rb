class BalanceSheet < Report
  attr_accessor :period, :branch_id

  def initialize(params, dates, user)
    @period = params && params[:period] ? AccountingPeriod.get(params[:period]) : nil
    get_parameters(params, user)
  end

  def name
    "Balance Sheet"
  end

  def self.name
    "Balance Sheet"
  end

  def generate
    data = {}
    accounting_period = AccountingPeriod.get(period) if period
    return data unless accounting_period
    ASSET_CLASSES.each do |asset_class|
      accounts_and_balances = {}
      Account.all(:asset_class => asset_class).each do |account|
        closing_balance = account.closing_balance_as_of accounting_period.end_date
        accounts_and_balances[account] = closing_balance
      end
      data[asset_class] = accounts_and_balances
    end
    data
  end
end   
