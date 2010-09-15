class AccountingPeriods < Application
  # provides :xml, :yaml, :js

  def index
    @accounting_periods = AccountingPeriod.all(:order => [:begin_date.asc])
    display @accounting_periods
  end

  def show(id)
    @accounting_period = AccountingPeriod.get(id)
    raise NotFound unless @accounting_period
    display @accounting_period
  end

  def new
    only_provides :html
    @accounting_period = AccountingPeriod.new
    display @accounting_period
  end

  def edit(id)
    only_provides :html
    @accounting_period = AccountingPeriod.get(id)
    raise NotFound unless @accounting_period
    display @accounting_period
  end

  def create(accounting_period)
    @accounting_period = AccountingPeriod.new(accounting_period)
    @accounting_period.created_by_user_id = session.user.id
    if @accounting_period.save
      redirect resource(:accounting_periods), :message => {:notice => "AccountingPeriod was successfully created"}
    else
      message[:error] = "AccountingPeriod failed to be created"
      render :new
    end
  end

  def update(id, accounting_period)
    @accounting_period = AccountingPeriod.get(id)
    raise NotFound unless @accounting_period
    if @accounting_period.update(accounting_period)
       redirect resource(:accounting_periods)
    else
      display @accounting_period, :edit
    end
  end

  def destroy(id)
    @accounting_period = AccountingPeriod.get(id)
    raise NotFound unless @accounting_period
    if @accounting_period.destroy
      redirect resource(:accounting_periods)
    else
      raise InternalServerError
    end
  end

end # AccountingPeriods
