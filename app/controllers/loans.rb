class Loans < Application
  before :get_context
  provides :xml, :yaml, :js
  before :ensure_has_mis_manager_privileges, :only => ['new','create','edit','update','destroy','delete']

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
    if Loan.descendants.map{|x| x.to_s}.include? params[:loan_type]
      begin
        klass = Kernel::const_get(params[:loan_type])
        @loan = klass.new
#       rescue
#         @loan = nil
      end
    end
    @loan_types = Loan.descendants if @loan.nil?
    display [@loan_types, @loan]
  end

  def create
    klass, attrs = get_loan_and_attrs
    @loan = klass.new(attrs)
    @loan.client = @client  # set direct context
    if @loan.save
      redirect resource(@branch, @center, @client, :loans), :message => {:notice => "Loan '#{@loan.id}' was successfully created"}
    else
      render :new  # error messages will be shown
    end
  end

  def edit(id)
    only_provides :html
    @loan = Loan.get(id)
    raise NotFound unless @loan
    display @loan
  end

  def update(id)
    klass, attrs = get_loan_and_attrs
    @loan = klass.get(id)
    raise NotFound unless @loan
    if @loan.update_attributes(attrs)
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


  # the loan is not of type Loan of a derived type, therefor we cannot just assume its name..
  # this method gets the loans type from a hidden field value and uses that to get the attrs
  def get_loan_and_attrs
    loan_key = params.keys.find { |x| x =~  /_loan$/ }  # loan params have the key like 'a50_loan'
    attrs = params[loan_key]
    raise NotFound if not params[:loan_type]
    klass = Kernel::const_get(params[:loan_type])
    [klass, attrs]
  end
end # Loans
