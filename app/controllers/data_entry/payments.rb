module DataEntry  
  class Payments < DataEntry::Controller
    provides :html, :xml
    def record
      @payment = (params and params[:id]) ? Payment.get(params[:id]) : Payment.new
      if params and params[:loan_id]
        @loan = Loan.get(params[:loan_id])
      end
      render
    end

    def by_center
      @center = Center.get(params[:center_id]) if params[:center_id]
      if params[:center_text] and not @center
        @center = Center.get(params[:center_text]) || Center.first(:name => params[:center_text]) || Center.first(:code => params[:center_text])
      end
      if params[:for_date]
        if params[:for_date][:month] and params[:for_date][:day] and params[:for_date][:year]
          params[:for_date] = "#{params[:for_date][:year]}-#{params[:for_date][:month]}-#{params[:for_date][:day]}"
        end
        @date = Date.parse(params[:for_date])
      end
      @branch = @center.branch unless @center.nil?
      if request.method == :post
        bulk_payments_and_disbursals
        if @errors.blank?
          redirect(params[:return]||url(:data_entry), :message => {:notice => 'All payments made succesfully'})
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
      amounts = payment[:amount].to_i
      receiving_staff = StaffMember.get(payment[:received_by])
      # we create payment through the loan, so subclasses of the loan can take full responsibility for it (validations and such)
      if payment[:type] == "total"
        succes, @prin, @int, @fees  = @loan.repay(amounts, session.user, parse_date(payment[:received_on]), receiving_staff)
      else
        payment[:received_by] = StaffMember.get(payment[:received_by]) #???
        payment[:created_by] = session.user
        @payment = Payment.new(payment)
        succes = @payment.save
      end
      if succes  # true if saved
        if params[:format]=='xml'
          display [@prin, @int, @fees], ""
        else
          redirect(params[:return] || url(:enter_payments, :action => 'record'), :message => {:notice => "Payment ##{@payment.id} has been registered"})
        end
      else
        @payment ||= Payment.new
        [@prin, @int, @fees].each {|o| o.errors.keys.each {|k| @payment.errors[k] = o.errors[k]} if o}
        params[:format]=='xml' ? display(@payment, :status => 400) : render(:record)
      end
    end
    
    def delete
      only_provides :html
      if params and params[:loan_id]
        @loan = Loan.get(params[:loan_id])
      end
      if params and params[:id]
        @payment = Payment.get(params[:id])
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
        redirect url(:data_entry), :message => {:notice => "Payment '#{@payment.id}' has been deleted"}
      else
        redirect url(:data_entry), :message => {:notice => "Could not delete payment '#{@payment.id}'. #{@payment.errors.to_hash.values}"}
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
      @staff = StaffMember.get(params[:payment][:received_by])
      @errors = []
      if params[:paid][:loan]
        params[:paid][:loan].keys.each do |k|
          @loan = Loan.get(k.to_i)
          amounts = params[:paid][:loan][k.to_sym].to_i
          if params[:submit] == "Pay Fees" # dangerous!
            @loan.pay_fees(amounts, @date, @staff, session.user)
            next
          end
          @type = params[:payment][:type]
          style = params[:payment_style][k.to_sym].to_sym
          success, @prin, @int, @fees = @loan.repay(amounts, session.user, @date, @staff, false, style)
          @errors << @prin.errors if (@prin and not @prin.errors.blank?)
          @errors << @int.errors if (@int and not @int.errors.blank? )
          @errors << @fees.errors if (@fees and not @fees.errors.blank?)
        end
      end
      if params[:paid][:client]
        params[:paid][:client].keys.each do |k|
          client = Client.get(k)
          x = client.pay_fees(params[:paid][:client][k.to_sym].to_i, @date, @staff, session.user)
          @errors << x unless x === true
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
