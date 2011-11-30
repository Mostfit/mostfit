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
        on_date = accounting_period.end_date > Date.today ? Date.today : accounting_period.end_date
        closing_balance = account.closing_balance_as_of on_date
        bal = closing_balance || 0.0
        accounts_and_balances[account] = bal
      end
      data[asset_class] = accounts_and_balances
    end
    data
  end
end   
