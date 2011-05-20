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
      total_change = 0.0
      Account.all(:income_head => income_head, :branch_id => branch_id).inject(total_change) do |total_change, account|
        net_change = account.change_closing_over_opening_balance_for_period accounting_period.begin_date
        total_change += net_change if net_change
      end
      data[income_head] = total_change
    end
    data
  # TODO: Display by individual accounts under each income head
  # TODO: Display side-by-side for chosen period and previous period
  end

end
