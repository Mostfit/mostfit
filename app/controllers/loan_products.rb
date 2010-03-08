class LoanProducts < Application
  # provides :xml, :yaml, :js

  def index
    @loan_products = LoanProduct.all
    display @loan_products
  end

  def show(id)
    @loan_product = LoanProduct.get(id)
    raise NotFound unless @loan_product
    display @loan_product
  end

  def new
    only_provides :html
    @loan_product = LoanProduct.new
    display @loan_product
  end

  def edit(id)
    only_provides :html
    @loan_product = LoanProduct.get(id)
    raise NotFound unless @loan_product
    display @loan_product
  end

  def create(loan_product)
    loan_product[:payment_validation_methods] = params[:payment_validations] ? params[:payment_validations].keys.join(",") : ""
    loan_product[:loan_validation_methods] = params[:loan_validations] ? params[:loan_validations].keys.join(",") : ""
    @loan_product = LoanProduct.new(loan_product)
    @loan_product.fees = []
    params[:fees] = params[:fees] || {}
    params[:fees].each do |k,v|
      f = Fee.get(k.to_i)
      @loan_product.fees << f if f
    end
    if @loan_product.save
      redirect resource(@loan_product), :message => {:notice => "LoanProduct was successfully created"}
    else
      message[:error] = "LoanProduct failed to be created"
      render :new
    end
  end

  def update(id, loan_product)
    @loan_product = LoanProduct.get(id)
    raise NotFound unless @loan_product
    fees = []
    if params[:fees]
      fees = params[:fees].map{|k,v| Fee.get(k.to_i)}
    end
    loan_product[:payment_validation_methods] = params[:payment_validations] ? params[:payment_validations].keys.join(",") : ""
    loan_product[:loan_validation_methods] = params[:loan_validations] ? params[:loan_validations].keys.join(",") : ""
    @loan_product.fees = fees
    @loan_product.attributes = loan_product
    if @loan_product.save
       redirect resource(@loan_product)
    else
      display @loan_product, :edit
    end
  end

  def destroy(id)
    @loan_product = LoanProduct.get(id)
    raise NotFound unless @loan_product
    if @loan_product.destroy
      redirect resource(:loan_products)
    else
      raise InternalServerError
    end
  end

  def design
    if request.method == :post
      params[:loan][:disbursal_date] = params[:loan][:scheduled_disbursal_date]
      params[:loan][:interest_rate]   = params[:loan][:interest_rate].to_f / 100
      @loan = Loan.new(params[:loan])
    else
      @loan = Loan.new
    end
    render
  end
end # LoanProducts
