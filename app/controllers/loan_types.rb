class LoanTypes < Application
  # provides :xml, :yaml, :js

  def index
    @loan_types = LoanType.all
    display @loan_types
  end

  def show(id)
    @loan_type = LoanType.get(id)
    raise NotFound unless @loan_type
    display @loan_type
  end

  def new
    only_provides :html
    @loan_type = LoanType.new
    display @loan_type
  end

  def edit(id)
    only_provides :html
    @loan_type = LoanType.get(id)
    raise NotFound unless @loan_type
    display @loan_type
  end

  def create(loan_type)
    @loan_type = LoanType.new(loan_type)
    if @loan_type.save
      redirect resource(@loan_type), :message => {:notice => "LoanType was successfully created"}
    else
      message[:error] = "LoanType failed to be created"
      render :new
    end
  end

  def update(id, loan_type)
    @loan_type = LoanType.get(id)
    raise NotFound unless @loan_type
    if @loan_type.update_attributes(loan_type)
       redirect resource(@loan_type)
    else
      display @loan_type, :edit
    end
  end

  def destroy(id)
    @loan_type = LoanType.get(id)
    raise NotFound unless @loan_type
    if @loan_type.destroy
      redirect resource(:loan_types)
    else
      raise InternalServerError
    end
  end

end # LoanTypes
