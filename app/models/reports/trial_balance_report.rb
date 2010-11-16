class TrialBalanceReport < Report
  attr_accessor :from_date, :to_date, :account, :account_id, :journal,:posting, :account_type_id, :branch, :branch_id

  def initialize(params,dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.min_date
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name      = "Trial Balance"
    @branch_id = params[:branch_id] if params and params.key?(:branch_id) and not params[:branch_id].blank?
  #  @page      = params[:page] ||0
    get_parameters(params, user)
  end

  def name
    "Trial Balance"
  end

  def self.name
    "Trial Balance"
  end


  def generate(param)
    data = {}
    Account.all(:order => [:account_type_id.asc], :parent_id => nil, :branch_id => @branch_id).group_by{|account| account.account_type}.each{|account_type, accounts|
      data[account_type] = recurse(accounts)
      account_type.opening_balance = aggregates(data[account_type], :opening_balance).reduce(0){|s, x| s+=x}
      account_type.debit  = aggregates(data[account_type], :debit).reduce(0){|s, x| s+=x}
      account_type.credit = aggregates(data[account_type], :credit).reduce(0){|s, x| s+=x}
      account_type.balance = aggregates(data[account_type], :balance).reduce(0){|s, x| s+=x}
    }
    data
  end

  def recurse(accounts)
    accounts.map{|account|
      account.debit  = (account.postings.sum(:amount, :amount.lte => 0)||0) * -1
      account.credit = (account.postings.sum(:amount, :amount.gte => 0)||0)
      account.balance = ((account.debit - account.credit) * -1) + account.opening_balance
      account.children.length>0 ? [account, recurse(account.children)] : account
    }
  end
  
  def aggregates(array, col)
    return [array.send(col) || 0] if array.class == Account
    return [0] unless array
    array.map{|parent, children|
      if parent.class == Account
        # parent is a Account
        parent.instance_variable_set("@#{col}", (parent.instance_variable_get("@#{col}") + aggregates(children, col).reduce(0){|s, x| s+=x}))
      else
        # parent is a collection of account
        aggregates(parent, col)
        aggregates(children, col)
      end
    }
  end
end   

