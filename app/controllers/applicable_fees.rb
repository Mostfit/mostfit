class ApplicableFees < Application
  # provides :xml, :yaml, :js

  def index
    @applicable_fees = ApplicableFee.all
    display @applicable_fees
  end

  def show(id)
    @applicable_fee = ApplicableFee.get(id)
    raise NotFound unless @applicable_fee
    display @applicable_fee
  end

  def new
    only_provides :html
    @applicable_fee = ApplicableFee.new
    display @applicable_fee
  end

  def edit(id)
    only_provides :html
    @applicable_fee = ApplicableFee.get(id)
    raise NotFound unless @applicable_fee
    display @applicable_fee
  end

  def create(applicable_fee)
    @applicable_fee = ApplicableFee.new(applicable_fee)
    if @applicable_fee.save
      redirect resource(@applicable_fee), :message => {:notice => "ApplicableFee was successfully created"}
    else
      message[:error] = "ApplicableFee failed to be created"
      render :new
    end
  end

  def update(id, applicable_fee)
    @applicable_fee = ApplicableFee.get(id)
    raise NotFound unless @applicable_fee
    if @applicable_fee.update(applicable_fee)
       redirect resource(@applicable_fee)
    else
      display @applicable_fee, :edit
    end
  end
end # ApplicableFees
