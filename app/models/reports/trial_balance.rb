class TrialBalance < Report
  
  attr_accessor :date, :branch_id

  def initialize(params,dates, user)
    @date = (dates and dates[:date]) ? dates[:date] : Date.today
    @branch_id = (params and params.key?(:branch_id) and not (params[:branch_id] == "")) ? params[:branch_id] : 0
    get_parameters(params, user)
  end

  def name
    "Trial Balance for #{get_branch_name(@branch_id)} on #{@date}"
  end

  def get_branch_name(branch_id)
    return "Head Office" if branch_id == 0
    branch = Branch.get(branch_id)
    branch ? branch.name : ""
  end

  def self.name
    "Trial Balance"
  end
  
  def generate(param)
    data = {}
    accounts = Account.all(:branch_id => @branch_id)
    accounts.each { |acc|
      balance = acc.closing_balance_as_of(@date)
      unless balance.nil?
        if balance == 0
          default_balance = acc.get_default_balance_type
          debit_balance, credit_balance = ( default_balance == CREDIT_BALANCE ? [nil, 0] : [0, nil] )
        else
          debit_balance, credit_balance = ( balance > 0 ? [nil, balance] : [balance, nil] )
        end
      else
        debit_balance, credit_balance = nil, nil
      end
      data[acc] = [debit_balance, credit_balance]
    }
    p data
    data
  end

end   

