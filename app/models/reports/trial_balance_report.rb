class TrialBalanceReport < Report
  attr_accessor :from_date, :to_date, :account, :account_id, :journal,:posting, :account_type_id, :branch, :branch_id, :display_type

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
    @branch_id = @branch_id.to_i if @branch_id 
    @debit_postings  = Posting.all(:amount.lt => 0).aggregate(:account_id, :amount.sum).to_hash
    @credit_postings = Posting.all(:amount.gt => 0).aggregate(:account_id, :amount.sum).to_hash
    
    Account.all(:order => [:account_type_id.asc], :parent_id => nil).group_by{|account| account.account_type}.each{|account_type, accounts|
      data[account_type] = recurse(accounts)    

      account_type.opening_balance_debit  = aggregates(data[account_type], :opening_balance_debit).reduce(0){|s, x| s+=x} || 0
      account_type.opening_balance_credit = aggregates(data[account_type], :opening_balance_credit).reduce(0){|s, x| s+=x} || 0

      account_type.debit  = aggregates(data[account_type], :debit).reduce(0){|s, x| s+=x}
      account_type.credit = aggregates(data[account_type], :credit).reduce(0){|s, x| s+=x}

      account_type.balance_debit = aggregates(data[account_type], :balance_debit).reduce(0){|s, x| s+=x}
      account_type.balance_credit = aggregates(data[account_type], :balance_credit).reduce(0){|s, x| s+=x}
    }
    data
  end

  def recurse(accounts)
    # iterate over accounts
    accounts.map{|account|
      if account.branch_id == @branch_id
        account.opening_balance_debit  = (account.opening_balance < 0 ? account.opening_balance * -1 : 0)
        account.opening_balance_credit = (account.opening_balance > 0 ? account.opening_balance : 0)
        
        account.debit  = (@debit_postings[account.id]||0) * -1
        account.credit = (@credit_postings[account.id]||0)
        
        if account.credit  + account.opening_balance_credit > account.debit + account.opening_balance_debit
          account.balance_credit = account.credit  + account.opening_balance_credit - account.debit - account.opening_balance_debit
          account.balance_debit  = 0          
        else
          account.balance_credit = 0
          account.balance_debit  = account.debit + account.opening_balance_debit - account.credit - account.opening_balance_credit
        end
      else
        next if account.children.length == 0
        account.opening_balance_debit  ||= 0
        account.opening_balance_credit ||= 0
        
        account.debit  ||= 0
        account.credit ||= 0

        account.balance_debit  ||= 0
        account.balance_credit ||= 0
      end

      if @branch_id == nil
        if account.children.length>0
          [account, recurse(account.children)]
        else
          account.branch_id == nil ? account : nil
        end
      else
        if account.children.length>0 
          [account, recurse(account.children)]
        else
          account.branch_id == @branch_id ? account : nil
        end
      end
    }.compact
  end
  
  def aggregates(array, col)
    return [array.send(col) || 0] if array.class == Account
    return [0] unless array
    array.map{|parent, children|
      if parent.class == Account
        # parent is a Account
        if col == :opening_balance_credit
          parent.opening_balance_credit = parent.opening_balance_credit + aggregates(children, col).reduce(0){|s, x| s+=x}
        elsif col == :opening_balance_debit
          parent.opening_balance_debit  = parent.opening_balance_debit  + aggregates(children, col).reduce(0){|s, x| s+=x}
        elsif col == :balance_credit
          parent.balance_credit = parent.balance_credit + aggregates(children, col).reduce(0){|s, x| s+=x}
        elsif col == :balance_debit
          parent.balance_debit  = parent.balance_debit + aggregates(children, col).reduce(0){|s, x| s+=x}
        else
          parent.instance_variable_set("@#{col}", (parent.instance_variable_get("@#{col}") + aggregates(children, col).reduce(0){|s, x| s+=x}))
        end
      else
        # parent is a collection of account
        aggregates(parent, col)
        aggregates(children, col)
      end
    }
  end
end   

