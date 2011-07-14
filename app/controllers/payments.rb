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
      if params[:format] and API_SUPPORT_FORMAT.include?(params[:format])
        display @payment
      else
        redirect url_for_loan(@loan||@client), :message => {:notice => "Payment of #{@payment.id} has been registered"}
      end
    else
      if params[:format] and API_SUPPORT_FORMAT.include?(params[:format])
        display @payment
      else
        render :new
      end
    end
  end

  def delete(id)
    only_provides :html
    @payment = Payment.get(id)
    raise NotFound unless @payment
    disallow_updation_of_verified_payments
    if @loan
      status, payment = @loan.delete_payment(@payment, session.user)
      if status
        redirect url_for_loan(@loan, 'payments'), :message => {:notice => "Payment '#{@payment.id}' has been deleted"}
      else
        msg = "Could not delete payment '#{@payment.id}' => "
        msg += payment.errors.to_a.flatten.uniq.join("/")
        redirect url_for_loan(@loan, 'payments'), :message => {:error => msg}
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
    date = parse_date(payment[:received_on])
    if ["total","fees"].include?(payment[:type]) and @loan
      @payment_type = payment[:type]
      # we create payment through the loan, so subclasses of the loan can take full responsibility for it (validations and such)
      if payment[:type] == "total"
        success, @prin, @int, @fees = @loan.repay(amounts, session.user, date, receiving_staff, true, params[:style].to_sym, context = :default, payment[:desktop_id], payment[:origin])
      else
        success, @fees = @loan.pay_fees(amounts, date, receiving_staff, session.user)
      end
      @payment = Payment.new
      @prin.errors.to_hash.each{|k,v| @payment.errors.add(k,v)}  if @prin
      @int.errors.to_hash.each{|k,v| @payment.errors.add(k,v)}  if @int
      @fees.map{|f| f.errors.to_hash.each{|k,v| @payment.errors.add(k,v)}}  if @fees
    else
      @payment_type = payment[:type] if payment[:type]
      @payment = Payment.new(payment)
      @payment.amount = amounts
      @payment.loan = @loan if @loan
      @payment.client = @client if @client
      @payment.created_by = session.user
      @payment.received_on = date
      success = @payment.save
      # reloading loan as payments can be stale here
    end
    Loan.get(@loan.id).update_history if @loan
    return success      
  end

end # Payments
