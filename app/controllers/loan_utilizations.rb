class LoanUtilizations < Application
  # provides :xml, :yaml, :js

  def index
    @loan_utilizations = LoanUtilization.all
    display @loan_utilizations
  end

  def show(id)
    @loan_utilization = LoanUtilization.get(id)
    raise NotFound unless @loan_utilization
    display @loan_utilization
  end

  def new
    only_provides :html
    @loan_utilization = LoanUtilization.new
    display @loan_utilization
  end

  def edit(id)
    only_provides :html
    @loan_utilization = LoanUtilization.get(id)
    raise NotFound unless @loan_utilization
    display @loan_utilization
  end

  def create(loan_utilization)
    @loan_utilization = LoanUtilization.new(loan_utilization)
    if @loan_utilization.save
      redirect resource(:loan_utilizations), :message => {:notice => "LoanUtilization was successfully created"}
    else
      message[:error] = "LoanUtilization failed to be created"
      render :new
    end
  end

  def update(id, loan_utilization)
    @loan_utilization = LoanUtilization.get(id)
    raise NotFound unless @loan_utilization
    if @loan_utilization.update(loan_utilization)
       redirect resource(:loan_utilizations)
    else
      display @loan_utilization, :edit
    end
  end

end # LoanUtilizations
