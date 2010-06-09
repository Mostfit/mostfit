class ChartOfAccounts < Application
  # provides :xml, :yaml, :js

  def index
    @chart_of_accounts = ChartOfAccount.all
    display @chart_of_accounts
  end

  def show(id)
    @chart_of_account = ChartOfAccount.get(id)
    raise NotFound unless @chart_of_account
    display @chart_of_account
  end

  def new
    only_provides :html
    @chart_of_account = ChartOfAccount.new
    display @chart_of_account
  end

  def edit(id)
    only_provides :html
    @chart_of_account = ChartOfAccount.get(id)
    raise NotFound unless @chart_of_account
    display @chart_of_account
  end

  def create(chart_of_account)
    @chart_of_account = ChartOfAccount.new(chart_of_account)
    if @chart_of_account.save
      redirect resource(@chart_of_account), :message => {:notice => "ChartOfAccount was successfully created"}
    else
      message[:error] = "ChartOfAccount failed to be created"
      render :new
    end
  end

  def update(id, chart_of_account)
    @chart_of_account = ChartOfAccount.get(id)
    raise NotFound unless @chart_of_account
    if @chart_of_account.update(chart_of_account)
       redirect resource(@chart_of_account)
    else
      display @chart_of_account, :edit
    end
  end

  def destroy(id)
    @chart_of_account = ChartOfAccount.get(id)
    raise NotFound unless @chart_of_account
    if @chart_of_account.destroy
      redirect resource(:chart_of_accounts)
    else
      raise InternalServerError
    end
  end

end # ChartOfAccounts
