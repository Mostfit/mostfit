class Payments < Application
  # provides :xml, :yaml, :js

  def index
    @payments = Payment.all
    display @payments
  end

  def show(id)
    @payment = Payment.get(id)
    raise NotFound unless @payment
    display @payment
  end

  def new
    only_provides :html
    @payment = Payment.new
    display @payment
  end

  def edit(id)
    only_provides :html
    @payment = Payment.get(id)
    raise NotFound unless @payment
    display @payment
  end

  def create(payment)
    @payment = Payment.new(payment)
    if @payment.save
      redirect resource(@payment), :message => {:notice => "Payment was successfully created"}
    else
      message[:error] = "Payment failed to be created"
      render :new
    end
  end

  def update(id, payment)
    @payment = Payment.get(id)
    raise NotFound unless @payment
    if @payment.update_attributes(payment)
       redirect resource(@payment)
    else
      display @payment, :edit
    end
  end

  def destroy(id)
    @payment = Payment.get(id)
    raise NotFound unless @payment
    if @payment.destroy
      redirect resource(:payments)
    else
      raise InternalServerError
    end
  end

end # Payments
