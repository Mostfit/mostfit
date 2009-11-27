module DataEntry  
  class Payments < DataEntry::Controller
    provides :html, :xml
    def record
      @payment = (params[:payment] and params[:payment][:id]) ? Payment.get(params[:payment][:id]) : Payment.new
      if params[:payment] and params[:payment][:loan_id]
        @loan = Loan.get(params[:payment][:loan_id])
      end
      render
    end

    def by_center
      @center = Center.get(params[:center_id]) if params[:center_id]
      @date = Date.parse(params[:for_date]) if params[:for_date]
      @branch = @center.branch unless @center.nil?
      if request.method == :post
        bulk_payments_and_disbursals
        if @errors.blank?
          redirect(url(:data_entry), :message => {:notice => 'All payments made succesfully'})
        elsif params[:format] and params[:format]=="xml"
          display("")
        else 
          render      
        end
      else
        render
      end
    end
    
    def by_staff_member
      debugger
      @date = params[:for_date] ? Date.parse(params[:for_date]) : Date.today
      staff_id = params[:staff_member_id] || params[:received_by]
      if staff_id
        @staff_member = StaffMember.get(staff_id.to_i)
        raise NotFound unless @staff_member
      end
      if request.method == :post
        if params[:paid] or params[:disbursed]
          bulk_payments_and_disbursals
        end
        if @errors.blank?
          redirect url(:enter_payments, :action => 'by_staff_member'), :message => {:notice => "All payments made succesfully"}
        else
          render
        end
      else
        #redirect url(:enter_payments, :action => 'by_staff_member', :staff_member_id => @staff_member.id, :for_date => @date)
        render
      end
    end
    
    def create(payment)
      raise NotFound unless @loan = Loan.get(payment[:loan_id])
      
      amounts = params[:total].to_i
      unless amounts > 0  # if no total is given we use the principal/interest duo
        amounts = [params[:principal].to_i, params[:interest].to_i]
      end
      receiving_staff = StaffMember.get(payment[:received_by])
      # we create payment through the loan, so subclasses of the loan can take full responsibility for it (validations and such)
      succes, @payment = @loan.repay(amounts, session.user, parse_date(payment[:received_on]), receiving_staff)
      if succes  # true if saved
        if params[:format]=='xml'
          display @payment, ""
        else
          redirect url(:enter_payments, :action => 'record'), :message => {:notice => "Payment ##{@payment.id} has been registered"}
        end
      else
        params[:format]=='xml' ? display(@payment, :status => 400) : render(:record)
      end
    end
    
    def delete
      only_provides :html
      if params[:payment] and params[:payment][:loan_id]
        @loan = Loan.get(params[:payment][:loan_id])
      end
      if params[:payment] and params[:payment][:id]
        @payment = Payment.get(params[:payment][:id])
      else
        @payment = Payment.new
      end
      render
    end
    
    def destroy
    @payment = Payment.get(params[:payment][:id]) if params[:payment] and params[:payment][:id]
      raise NotFound unless @payment
      @loan = @payment.loan
      if @loan.delete_payment(@payment, session.user)
        redirect url(:enter_payments), :message => {:notice => "Payment '#{@payment.id}' has been deleted"}
      else
        redirect url(:enter_payments), :message => {:error => "Could not delete payment '#{@payment.id}'"}
      end
    end
    
    private
    include DateParser
    # this function is called by by_center and by_staff_member
    def bulk_payments_and_disbursals
      @center = Center.get(params[:center_id]) || Center.first(:name => params[:center_id]) 
      @branch = @center.branch unless @center.nil?
      @clients = @center.clients unless @center.nil?
      @date = Date.parse(params[:for_date]) unless params[:for_date].nil?
      @errors = []
      if params[:paid]
        params[:paid].keys.each do |k|
          @loan = Loan.get(k.to_i)
          @staff = StaffMember.get(params[:payment][:received_by])
          amounts = params[:paid][k.to_sym].to_i
          success, @payment = @loan.repay(amounts, session.user, @date, @staff, false)
          @errors << @payment.errors if not success
        end
      end
      if params[:disbursed]
        params[:disbursed].each do |k,v|
          next if v != "on"
          @loan = Loan.get(k.to_i)
          @loan.disbursal_date = @date
          @loan.disbursed_by = @staff
          @errors << @loan.errors if not @loan.save
        end
      end
    end

  end
end
