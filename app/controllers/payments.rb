class Payments < Application
  before :get_context
  provides :xml, :yaml, :js

  def index
    @payments = @loan.payments
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

  def create(payment)
    amounts = payment[:total].to_i
    unless amounts > 0  # if no total is given we use the principal/interest duo
      amounts = [payment[:principal].to_i, payment[:interest].to_i]
    end
    # we create payment through the loan, so subclasses of the loan can take full responsibility for it (validations and such)
    succes, @payment = @loan.repay(amounts, session.user, Date.strptime(payment[:received_on]), payment[:received_by])
    if succes  # true if saved
      redirect resource(@branch, @center, @client, @loan), :message => {:notice => "Payment ##{@payment.id} has been registered"}
    else
      message[:error] = "Payment failed to be created"
      render :new
    end
  end

#   def edit(id)
#     only_provides :html
#     @payment = Payment.get(id)
#     raise NotFound unless @payment
#     display @payment
#   end
# 
#   def update(id, payment)
#     @payment = Payment.get(id)
#     raise NotFound unless @payment
#     if @payment.update_attributes(payment)
#        redirect resource(@payment)
#     else
#       display @payment, :edit
#     end
#   end

  def delete(id)
    only_provides :html
    @payment = Payment.get(id)
    raise NotFound unless @payment
    display @payment
  end

  def destroy(id)
    @payment = Payment.get(id)
    raise NotFound unless @payment
    if @payment.destroy
      redirect resource(@branch, @center, @client, @loan, :payments), :message => {:notice => "Payment '#{@payment.id}' has been deleted"}
    else
      raise InternalServerError
    end
  end


  private
  def get_context
    @branch = Branch.get(params[:branch_id])
    @center = Center.get(params[:center_id])
    @client = Client.get(params[:client_id])
    @loan   = Loan.get(params[:loan_id])
    raise NotFound unless @branch and @center and @client and @loan
  end
end # Payments
