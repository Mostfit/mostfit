class Accounts < Application
  # provides :xml, :yaml, :js

  def index
    if request.xhr? and params[:account_type_id]
      @accounts = Account.all(:account_type_id => params[:account_type_id])
      partial :accounts_selection
    else
      @accounts = Account.all
      display @accounts
    end
  end

  def show(id)
    @account = Account.get(id)
    raise NotFound unless @account
    display @account
  end

  def new
    only_provides :html
    @account = Account.new
    display @account
  end

  def edit(id)
    only_provides :html
    @account = Account.get(id)
    raise NotFound unless @account
    display @account
  end

  def create(account)
    @account = Account.new(account)
    if @account.save
      redirect resource(@account), :message => {:notice => "Account was successfully created"}
    else
      message[:error] = "Account failed to be created"
      render :new
    end
  end

  def update(id, account)
    @account = Account.get(id)
    raise NotFound unless @account
    if @account.update(account)
       redirect resource(@account)
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

end # Accounts
