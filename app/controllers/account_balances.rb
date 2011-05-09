class AccountBalances < Application
  # provides :xml, :yaml, :js
  before :get_context, :exclude => [:index] 


  def index
    opts = {}
    opts[:account] = @account if @account
    opts[:accounting_period] = @accounting_period if @accounting_period
    @account_balances = AccountBalance.all(opts)
    display @account_balances
  end

  def show(id)
    display @account_balance
  end

  def new
    only_provides :html
    @account_balance = AccountBalance.new
    display @account_balance
  end

  def edit(id)
    only_provides :html
    raise NotFound unless @account_balance
    display @account_balance
  end

  def create(account_balance)
    @account_balance = AccountBalance.new(account_balance)
    @account_balance.account = @account
    @account_balance.accounting_period = @accounting_period
    if @account_balance.save
      redirect resource(@account_balance), :message => {:notice => "AccountBalance was successfully created"}
    else
      message[:error] = "AccountBalance failed to be created"
      render :new
    end
  end

  def update(id, account_balance)
    raise NotFound unless @account_balance
    raise NotPrivileged if (@account_balance.verified_by and (not session.user.role == :admin))
    account_balance.delete(:account_id)
    account_balance.delete(:accounting_period_id)
    @account_balance.account = @account
    @account_balance.accounting_period = @accounting_period

   if @account_balance.update(account_balance)
     redirect resource(@account, @accounting_period,:account_balances), :message => {:notice => "Balance updated"}
    else
      display @account_balance, :edit
    end
  end

  def verify(id)
    raise NotPrivileged unless  session.user.role == :admin
    raise NotFound unless @account_balance
    if request.method == :get
      render
    else
      @account_balance.verified_on = Date.today
      @account_balance.verified_by = session.user
      if  @account_balance.save
        redirect resource(@account, @accounting_period,:account_balances), :message => {:notice => "Account verified and closed"}
      else
        redirect resource(@account_balance), :message => {:error => "Could not be verified"}
      end
    end
  end

  def destroy(id)
    @account_balance = AccountBalance.get(id)
    raise NotFound unless @account_balance
    if @account_balance.destroy
      redirect resource(:account_balances)
    else
      raise InternalServerError
    end
  end

  private
  
  def get_context
    @account_balance = AccountBalance.get(id) if params[:id]
    if @account_balance
      @account = @account_balance.account
      @accounting_period = @account_balance.accounting_period
    else
      @account = Account.get(params[:account_id]) if params[:account_id]
      @accounting_period = AccountingPeriod.get(params[:accounting_period_id])
      @account_balance = AccountBalance.all(:account => @account, :accounting_period => @accounting_period)[0]
    end
    raise NotFound unless @account
    raise NotFound unless @accounting_period
  end

end # AccountBalances
