class LoanPurposes < Application
  # provides :xml, :yaml, :js

  before :all_loan_purposes, :only => [:new, :create, :update]
  def index
    @loan_purposes = LoanPurpose.all
    display @loan_purposes
  end

  def show(id)
    @loan_purpose = LoanPurpose.get(id)
    raise NotFound unless @loan_purpose
    display @loan_purpose
  end

  def new
    only_provides :html
    @loan_purpose = LoanPurpose.new
    display @loan_purpose
  end

  def edit(id)
    only_provides :html
    @loan_purpose = LoanPurpose.get(id)
    @parents = LoanPurpose.all(:conditions => ['id != ?', id])
    raise NotFound unless @loan_purpose
    display @loan_purpose
  end

  def create(loan_purpose)
    @loan_purpose = LoanPurpose.new(loan_purpose)
    @loan_purpose.parent_id = 0 if @loan_purpose.parent_id.blank?
    if @loan_purpose.save
      redirect resource(@loan_purpose), :message => {:notice => "LoanPurpose was successfully created"}
    else
      message[:error] = "LoanPurpose failed to be created"
      render :new
    end
  end

  def update(id, loan_purpose)
    @loan_purpose = LoanPurpose.get(id)
    loan_purpose['parent_id'] = 0 if loan_purpose['parent_id'].blank?
    raise NotFound unless @loan_purpose
    if @loan_purpose.update(loan_purpose)
       redirect resource(@loan_purpose)
    else
      display @loan_purpose, :edit
    end
  end

  def destroy(id)
    @loan_purpose = LoanPurpose.get(id)
    raise NotFound unless @loan_purpose
    if @loan_purpose.destroy
      redirect resource(:loan_purposes)
    else
      raise InternalServerError
    end
  end

  def all_loan_purposes
    @parents = LoanPurpose.all
  end
end # LoanPurposes
