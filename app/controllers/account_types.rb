class AccountTypes < Application
  # provides :xml, :yaml, :js

  def index
    @account_types = AccountType.all
    display @account_types
  end

  def show(id)
    @account_type = AccountType.get(id)
    raise NotFound unless @account_type
    display @account_type
  end

  def new
    only_provides :html
    @account_type = AccountType.new
    display @account_type
  end

  def edit(id)
    only_provides :html
    @account_type = AccountType.get(id)
    raise NotFound unless @account_type
    display @account_type
  end

  def create(account_type)
    @account_type = AccountType.new(account_type)
    if @account_type.save
      redirect resource(:account_types), :message => {:notice => "AccountType was successfully created"}
    else
      message[:error] = "AccountType failed to be created"
      render :new
    end
  end

  def update(id, account_type)
    @account_type = AccountType.get(id)
    raise NotFound unless @account_type
    if @account_type.update(account_type)
       redirect resource(:account_types)
    else
      display @account_type, :edit
    end
  end

  def destroy(id)
    @account_type = AccountType.get(id)
    raise NotFound unless @account_type
    if @account_type.destroy
      redirect resource(:account_types)
    else
      raise InternalServerError
    end
  end

end # AccountTypes
