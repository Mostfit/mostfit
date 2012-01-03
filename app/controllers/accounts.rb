class Accounts < Application
  # provides :xml, :yaml, :js
  before :get_context

  def index
    if params[:branch_id] and not params[:branch_id].blank?
      @branch =  Branch.get(params[:branch_id])
    else
      params[:branch_id] = "0"
      @branch = nil
    end
    @accounts = Account.tree((params[:branch_id] and not params[:branch_id].blank?) ? params[:branch_id].to_i : nil )
    if params[:account_type_id] and (not params[:account_type_id].blank?)
      # bizarre result from to_hash compels me to take the scenic route - svs
      at  = AccountType.get(params[:account_type_id])
      na = {}
      na[at] = @accounts[at]
      @accounts = na
    end
    template = request.xhr? ? 'accounts/select' : 'accounts/index'
    display @accounts, template, :layout => layout?
  end

  def show(id)
    @account = Account.get(id)
    raise NotFound unless @account
    display @account, :layout => layout?
  end

  def new
    only_provides :html
    @account = Account.new
    @accounts = Account.tree(nil)
    display @account, :layout => layout?
  end

  def edit(id)
    only_provides :html
    @account = Account.get(id)
    raise NotFound unless @account
 
    if @account.account_type
      @branch = Branch.get(@account.branch_id) if @account.branch_id
      @accounts = Account.tree(@account.branch_id || nil)
    end
    display @account, :layout => layout?
  end

  def create(account)
    if account.is_a?(Hash)
      @account = Account.new(account)
      @account.opening_balance = -params['account']['opening_balance'].to_f if params['txn_type'] == 'debit'  
      if params['account']['opening_balance'].to_f < 0
        message[:error] = "Account balance cannot be negative. Please choose credit or debit and enter a positive number for the account opening balance."
        render :new
      elsif @account.save && params['account']['opening_balance'].to_f >= 0
        redirect resource(:accounts, :branch_id => account[:branch_id] || 0), :message => {:notice => "Account was successfully created"}
      else
        message[:error] = "Account failed to be created"
        render :new
      end
    elsif account.is_a?(Array)
      #bulk creating accounts
      if (params[:branch_id] and branch = Branch.get(params[:branch_id]))
        errors = bulk_create_for(branch, account)
        if errors.blank?
          redirect resource(:accounts), :message => {:notice => "All accounts were successfully created"}
        else
          message[:error] = "Some accounts failed to be created"
          message[:error] += "<ul>"
          errors.each{|error|
            message[:error] += error.instance_variable_get("@errors").map{|k, v| "<li>#{error.name} - #{k}: #{v}</li>"}.to_s
          }
          message[:error] += "</ul>"
          @branch = Branch.get(params[:parent_branch_id])
          @accounts = Account.all(:branch => @branch) if @branch     
          render :duplicate
        end
      else
        message[:error] = "No branch selected"
        @branch = Branch.get(params[:parent_branch_id])
        @accounts = Account.all(:branch => @branch) if @branch
        render :duplicate
      end
    end
  end

  def update(id, account)
    @account = Account.get(id)
    raise NotFound unless @account

    account['parent_id'] = nil if account['parent_id'].empty?
    if params['account']['opening_balance'].to_f < 0
      message[:error] = "Account failed to be updated. Account opening balance cannot be negative. Please choose credit or debit and enter a positive number for the account opening balance."
      display @account, :edit
    elsif @account.update(account)
      @account.opening_balance = -params['account']['opening_balance'].to_f if params['txn_type'] == 'debit'
      if @account.save
        redirect resource(:accounts, :branch_id => @account.branch_id)
      else
        display @account, :edit
      end
    else
      display @account, :edit
    end
  end

  def destroy(id)
    @account = Account.get(id)
    raise NotFound unless @account
    if @account.destroy
      redirect resource(:accounts)
    else
      raise InternalServerError
    end
  end

  def branch
    @journal = Journal.new
    render :layout => layout?
  end

  def duplicate
    unless params[:branch_id].blank?
      if params[:branch_id] == "0"
        @branch = Branch.new(:name => "HO", :id => 0)
      else
        @branch = Branch.get(params[:branch_id])
      end
      raise NotFound unless @branch
      @accounts = Account.all(:branch_id => params[:branch_id])
    end
    render :layout => layout?
  end

  def book
    if params[:accounting_period_id] and not params[:accounting_period_id].blank?
      @accounting_period = AccountingPeriod.get(params[:accounting_period_id])
    else
      @accounting_period = AccountingPeriod.all(:order => [:end_date]).last
    end
    @account = Account.get(params[:account_id])
    @from_date = (@accounting_period ? @accounting_period.begin_date : @account.account_earliest_date - 1)
    @to_date =  (@accounting_period ? @accounting_period.end_date : Date.today)
    journal_ids = Journal.all(:date.gte => @from_date, :date.lte => @to_date).map{|x| x.id}
    @posting_hash = Posting.all(:account => @account, :journal_id => journal_ids)
    partial :book, :layout => layout?
  end

  private
  def get_context
    @branches_list = Branch.all.map{ |x| [x.id, x.name]}
    @branches_list.unshift([0, 'Head Office Accounts'])
    @branch = Branch.get(params[:branch_id]) if params.key?(:branch_id)
  end

  def bulk_create_for(branch, accounts)
    errors = []
    accounts.each{|a|
      new_account = Account.new(a)
      new_account.branch = branch
      unless new_account.save
        errors.push(new_account)
      end
    }
    errors
  end

end # Accounts
