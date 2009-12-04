class Loans < Application
  before :get_context, :exclude => ['redirect_to_show']
  provides :xml, :yaml, :js

  def index
    @loans = @client.loans
    display @loans
  end

  def latest
    @offset = params[:page].to_i -1
    @limit = 20
    @loans = Loan.all(:order => [:created_at.desc], :offset => @offset, :limit => 10)
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
    if params[:product_id] and @loan_product = LoanProduct.is_valid(params[:product_id])
      if Loan.descendants.map{|x| x.to_s}.include?(@loan_product.loan_type)
        klass = Kernel::const_get(@loan_product.loan_type)
        @loan = klass.new
      end
    end
    @loan_products = LoanProduct.valid if @loan.nil?
    display [@loan_types, @loan]
  end

  def create
    klass, attrs = get_loan_and_attrs
    attrs[:interest_rate] = attrs[:interest_rate].to_f / 100 if attrs[:interest_rate].to_f > 0
    @loan = klass.new(attrs)
    raise NotFound if not @loan.client  # should be known though hidden field
    @loan_product = LoanProduct.is_valid(params[:loan_product_id])
    @loan.loan_product_id = @loan_product.id     
    if @loan.save
      redirect resource(@branch, @center, @client, :loans), :message => {:notice => "Loan '#{@loan.id}' was successfully created"}
    else
      @loan.interest_rate *= 100
      render :new  # error messages will be shown
    end
  end

  def edit(id)
    only_provides :html
    @loan = Loan.get(id)
    @loan_product =  @loan.loan_product
    raise NotFound unless @loan
    display @loan
  end

  def update(id)
    klass, attrs = get_loan_and_attrs
    attrs[:interest_rate] = attrs[:interest_rate].to_f / 100 if attrs[:interest_rate].to_f > 0
    @loan = klass.get(id)
    @loan_product =  @loan.loan_product
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

  # this redirects to the proper url, used from the router
  def redirect_to_show(id)
    raise NotFound unless @loan = Loan.get(id)
    @branch, @center, @client = @loan.client.center.branch, @loan.client.center, @loan.client
    redirect url_for_loan(@loan)
  end


  private
  def get_context
    if params[:id]
      @loan = Loan.get(params[:id])
      raise NotFound unless @loan
      @client = @loan.client
      @center = @client.center
      @branch = @center.branch
    else
      @client = Client.get(params[:client_id])
      @center = Center.get(params[:center_id])
      @branch = Branch.get(params[:branch_id])
      raise NotFound unless @branch and @center and @client
    end
  end

  # the loan is not of type Loan of a derived type, therefor we cannot just assume its name..
  # this method gets the loans type from a hidden field value and uses that to get the attrs
  def get_loan_and_attrs   # FIXME: this is a code dup with data_entry/loans
    loan_product = LoanProduct.get(params[:loan_product_id])
    attrs = params[loan_product.loan_type.snake_case.to_sym]
    attrs[:client_id]=params[:client_id] if params[:client_id]
    raise NotFound if not params[:loan_type]
    klass = Kernel::const_get(params[:loan_type])
    [klass, attrs]
  end
end # Loans
