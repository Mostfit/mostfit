class Loans < Application
  before :get_context
  provides :xml, :yaml, :js

  def index
    @loans = @client.loans
    display @loans
  end

  def show(id)
    @loan = Loan.get(id)
    raise NotFound unless @loan
    @payments = @loan.payments
    display [@loan, @payments], 'payments/index'
  end

  def new
    only_provides :html
    @loan = Loan.new
    display @loan
  end

  def create(loan)
    @loan = Loan.new(loan)
    @loan.client = @client  # set direct context
    if @loan.save
      redirect resource(@branch, @center, @client, :loans), :message => {:notice => "Loan '#{@loan.id}' was successfully created"}
    else
#       message[:error] = "Loan failed to be created"
      render :new  # error messages will be shown
    end
  end

  def edit(id)
    only_provides :html
    @loan = Loan.get(id)
    raise NotFound unless @loan
    display @loan
  end

  def update(id, loan)
    @loan = Loan.get(id)
    raise NotFound unless @loan
    if @loan.update_attributes(loan)
       redirect resource(@branch, @center, @client, :loans), :message => {:notice => "Loan '#{@loan.id}' has been edited"}
    else
      display @loan, :edit  # error messages will be shown
    end
  end

  def delete(id)
    edit(id)  # so far these are the same
  end

  def destroy(id)
    @loan = Loan.get(id)
    raise NotFound unless @loan
    if @loan.destroy
      redirect resource(@branch, @center, @client, :loans), :message => {:notice => "Loan '#{@loan.id}' has been deleted"}
    else
      raise InternalServerError
    end
  end

  private
  def get_context
    @branch = Branch.get(params[:branch_id])
    @center = Center.get(params[:center_id])
    @client = Client.get(params[:client_id])
    raise NotFound unless @branch and @center and @client
  end
end # Loans
