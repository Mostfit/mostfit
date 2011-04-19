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
      url = (@applicable_fee.parent.is_a?(Loan) ? "/loans/#{@applicable_fee.applicable_id}" : resource(@applicable_fee.parent))
      if request.xhr?
        render "<div class='notice'>Fee was successfully levied</div>", :layout => layout?
      else
        redirect(url, :message => {:notice => "Fee was successfully levied"})
      end
    else
      if request.xhr?
        render(error_messages_for(@applicable_fee), :status => 406, :layout => layout?)
      else
        render @applicable_fee.parent
      end
    end
  end
end # ApplicableFees
