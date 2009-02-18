module DataEntry

class Loans < DataEntry::Controller
  def new
    @loan = (params[:loan] and params[:loan][:id]) ? Loan.get(params[:loan][:id]) : Loan.new
    if params[:client_id]
      @client = Client.get(params[:client_id])
    end
    render
  end

  def create
    klass, attrs = get_loan_and_attrs
    @loan = klass.new(attrs)
    raise NotFound if not @loan.client  # should be known though hidden field
    @client = @loan.client
    if @loan.save
      redirect url(:enter_loans, :action => 'new'), :message => {:notice => "Loan '#{@loan.id}' was successfully created"}
    else
      render :new  # error messages will be shown
    end
  end

  def edit
    @loan = (params[:loan] and params[:loan][:id]) ? Loan.get(params[:loan][:id]) : Loan.new
    render
  end

  def update
    raise NotFound unless params[:loan] and params[:loan][:id]
    klass, attrs = get_loan_and_attrs
    @loan = klass.get(params[:loan][:id])
    raise NotFound unless @loan
    if @loan.update_attributes(attrs)
       redirect url(:enter_loans, :action => 'edit'), :message => {:notice => "Loan '#{@loan.id}' has been edited"}
    else
      render :edit
    end
  end

  private
  # the loan is not of type Loan of a derived type, therefor we cannot just assume its name..
  # this method gets the loans type from a hidden field value and uses that to get the attrs
  def get_loan_and_attrs   # FIXME: this is a code dup with the loans contoller
    loan_key = params.keys.find { |x| x =~  /loan$/ }  # loan params have the key like 'a50_loan' or 'loan'
    attrs = params[loan_key]
    raise NotFound if not params[:loan_type]
    klass = Kernel::const_get(params[:loan_type])
    [klass, attrs]
  end
end

end