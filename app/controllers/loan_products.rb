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
    @loan_product = LoanProduct.new(loan_product)
    if @loan_product.save
      redirect resource(@loan_product), :message => {:notice => "LoanProduct was successfully created"}
    else
      message[:error] = "LoanProduct failed to be created"
      render :new
    end
  end

  def update(id, loan_product)
    debugger
    @loan_product = LoanProduct.get(id)
    raise NotFound unless @loan_product
    if @loan_product.update_attributes(loan_product)
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

end # LoanProducts
