class Payments < Application
  before :get_context
  provides :xml, :yaml, :js

  def index
    @payments = @loan.payments
    display @payments
  end

#   def show(id)
#     @payment = Payment.get(id)
#     raise NotFound unless @payment
#     display @payment
#   end

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
    receiving_staff = StaffMember.get(payment[:received_by])
    # we create payment through the loan, so subclasses of the loan can take full responsibility for it (validations and such)
    succes, @payment = @loan.repay(amounts, session.user, parse_date(payment[:received_on]), receiving_staff)
    if succes  # true if saved
      redirect url_for_loan(@loan), :message => {:notice => "Payment ##{@payment.id} has been registered"}
    else
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
    if @loan.delete_payment(@payment, session.user)
      redirect url_for_loan(@loan, 'payments'), :message => {:notice => "Payment '#{@payment.id}' has been deleted"}
    else
      redirect url_for_loan(@loan, 'payments'), :message => {:error => "Could not delete payment '#{@payment.id}'"}
    end
  end


  private
  include DateParser

  def get_context
    @branch = Branch.get(params[:branch_id])
    @center = Center.get(params[:center_id])
    @client = Client.get(params[:client_id])
    @loan   = Loan.get(params[:loan_id])
    raise NotFound unless @branch and @center and @client and @loan
  end
end # Payments
