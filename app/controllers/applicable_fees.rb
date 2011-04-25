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
    raise NotPrivileged unless [:admin, :mis_manager].include?(session.user.role)
    only_provides :html
    @applicable_fee = ApplicableFee.get(id)
    raise NotFound unless @applicable_fee
    display @applicable_fee
  end

  def create(applicable_fee)
    @applicable_fee = ApplicableFee.new(applicable_fee)
    if @applicable_fee.save
      url = (@applicable_fee.parent.is_a?(Loan) ? "/loans/#{@applicable_fee.applicable_id}" : resource(@applicable_fee.parent))
      redirect(url, :message => {:notice => "Fee was successfully levied"})
    else
      if request.xhr?
        render(error_messages_for(@applicable_fee), :status => 406, :layout => layout?)
      else
        message[:error] = "Fees cannot be saved"
        render :new
      end
    end
  end

  def update(id, applicable_fee)
    @applicable_fee = ApplicableFee.get(id)
    if @applicable_fee.update(applicable_fee)
      url = (@applicable_fee.parent.is_a?(Loan) ? "/loans/#{@applicable_fee.applicable_id}" : resource(@applicable_fee.parent))
      redirect(url, :message => {:notice => "Fee was successfully updated"})
    else
      render
    end
  end


end # ApplicableFees
