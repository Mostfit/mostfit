class Payments < Application
  before :get_context, :exclude => ['redirect_to_show']
  provides :xml, :yaml, :js

  def index
    if @loan
      @payments = @loan.payments(:order => [:received_on, :id])
      display @payments
    elsif @client
      @payments = @client.payments(:order => [:received_on, :id])
      partial :list      
    end
  end

  def new
    only_provides :html
    @payment = Payment.new
    display @payment
  end

  def show(id)
    display @payment
  end

  def edit(id)
    @payment = Payment.get(id)
    raise NotFound unless @payment
    display @payment
  end

  def update(id, payment)
    @payment = Payment.get(id)
    raise NotFound unless @payment
    disallow_updation_of_verified_payments
    return unless session.user.role == :admin
    if @loan and @loan.delete_payment(@payment, session.user)
      if do_payment(payment)
        redirect url_for_loan(@loan, 'payments'), :message => {:notice => "Payment '#{id}' has been deleted and a new one #{@payment.id} created"}
      else
        redirect(url_for_loan(@loan, 'payments'), 
                 :message => {:error => "Payment '#{id}' has been deleted but a new one could not be created because #{@payment.errors.instance_variable_get("@errors").map{|k, v| v.join(", ")}.join(", ")}"})
      end
    elsif @client and @payment.deleted_by = session.user and @payment.destroy      
      do_payment(payment)
      redirect url_for_loan(@client, 'payments'), :message => {:notice => "Payment '#{id}' has been deleted and a new one #{@payment.id} created"}      
    else
      render :edit
    end
  end

  def create(payment)
    raise NotFound unless (@loan or @client)
    success = do_payment(payment)
    if success  # true if saved
      redirect url_for_loan(@loan||@client), :message => {:notice => "Payment of ##{@payment.id} has been registered"}
    else
      render :new
    end
  end

  def delete(id)
    only_provides :html
    @payment = Payment.get(id)
    raise NotFound unless @payment
    disallow_updation_of_verified_payments
    if @loan
      if @loan.delete_payment(@payment, session.user)
        redirect url_for_loan(@loan, 'payments'), :message => {:notice => "Payment '#{@payment.id}' has been deleted"}
      else
        redirect url_for_loan(@loan, 'payments'), :message => {:error => "Could not delete payment '#{@payment.id}'"}
      end
    else
      @client = @payment.client
      if @payment.destroy!
        redirect resource(@client), :message => {:notice => "Payment was deleted"}
      else
        display @payment, :message => {:notice => 'Payment was not deleted'}
      end
    end
  end

  def destroy(id)
    @payment = Payment.get(id)
    raise NotFound unless @payment
    disallow_updation_of_verified_payments
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
    @loan   = Loan.get(params[:loan_id]) if params[:loan_id]
    raise NotFound unless @branch and @center and @client
  end

  def disallow_updation_of_verified_payments
    raise NotPrivileged if @payment.verified_by_user_id and not session.user.admin?
  end

  def do_payment(payment)
    amounts = payment[:amount].to_f
    receiving_staff = StaffMember.get(payment[:received_by_staff_id])
    if payment[:type] == "total" and @loan
    # we create payment through the loan, so subclasses of the loan can take full responsibility for it (validations and such)
      success, @prin, @int, @fees = @loan.repay(amounts, session.user, parse_date(payment[:received_on]), receiving_staff, true, params[:style].to_sym)
      @payment = Payment.new
      @prin.errors.to_hash.each{|k,v| @payment.errors.add(k,v)}  if @prin
      @int.errors.to_hash.each{|k,v| @payment.errors.add(k,v)}  if @int
      @fees.errors.to_hash.each{|k,v| @payment.errors.add(k,v)}  if @fees
      # reloading loan as payments can be stale here
      Loan.get(@loan.id).update_history(true) if success and @loan
      return success
    else
      @payment = Payment.new(payment)
      @payment.loan = @loan if @loan
      @payment.client = @client if @client
      @payment.created_by = session.user
      @payment.received_on = payment[:received_on]
      if payment[:type]=="fees" and @payment.received_on
        obj = @loan || @client
        if fee = obj.fees_payable_on[@payment.received_on]
          @payment.fee = fee
        else
          fees = obj.fee_schedule.reject{|d, f| d>@payment.received_on}.values.collect{|x| x.keys}.flatten - obj.fee_payments.values.collect{|x| x.keys}.flatten
          @payment.fee = fees.first if fees and fees.length>0
        end
      end
      success = @payment.save
      # reloading loan as payments can be stale here
      Loan.get(@loan.id).update_history if success and @loan
      return success      
    end
  end
end # Payments
