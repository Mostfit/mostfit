module DataEntry
  class Payments < DataEntry::Controller
    include Pdf::DaySheet if PDF_WRITER
    provides :html, :xml
    def record
      @payment = (params and params[:id]) ? Payment.get(params[:id]) : Payment.new
      if params and params[:loan_id]
        @loan = Loan.get(params[:loan_id])
      end
      render
    end

    def by_center
      @option = params[:option] if params[:option]
      @info = params[:info] if params[:info]
      @center = Center.get(params[:center_id]) if params[:center_id]
      if params[:center_text] and not @center
        @center = Center.get(params[:center_text]) || Center.first(:name => params[:center_text]) || Center.first(:code => params[:center_text])
      end

      # if recieved on is present use that, else use for_date (old hidden field) or use today's date
      if params[:received_on] and not params[:received_on].blank?
        @date = Date.parse(params[:received_on])
      elsif params[:for_date] and not params[:for_date].blank?
        if params[:for_date][:month] and params[:for_date][:day] and params[:for_date][:year]
          params[:for_date] = "#{params[:for_date][:year]}-#{params[:for_date][:month]}-#{params[:for_date][:day]}"  
        end
        @date = Date.parse(params[:for_date])
      else
        @date = Date.today
      end

      unless @center.nil?
        @branch = @center.branch
        @clients = Client.all(:center_id => @center.id, :fields => [:id, :name, :center_id, :client_group_id])
        @loans   = Loan.all(:c_center_id => @center.id, :rejected_on => nil)
        @disbursed_loans = @loans.all(:disbursal_date.not => nil)
        @undisbursed_loans = @loans.all(:disbursal_date => nil, :approved_on.not => nil)
        @loans_to_approve = @loans.all(:approved_on  => nil)
        @loans_to_utilize = @disbursed_loans.all(:loan_utilization_id => nil)
        date_with_holiday = [@date, @date.holidays_shifted_today].max
        @loans_to_disburse = @undisbursed_loans.all(:scheduled_disbursal_date.lte => date_with_holiday)
        @fee_paying_loans   = @loans.collect{|x| {x => x.fees_payable_on(@date)}}.inject({}){|s,x| s+=x}
        @fee_paying_clients = @clients.collect{|x| {x => x.fees_payable_on(@date)}}.inject({}){|s,x| s+=x}
        @fee_paying_things = @fee_paying_clients + @fee_paying_loans

        
      end

      if request.method == :post
        if Date.min_transaction_date > @date or Date.max_transaction_date < @date
          @errors = "Transactions attempted are outside allowed dates"
        else
          bulk_payments_and_disbursals
          mark_attendance
        end
        if @errors.blank?
          return_url = params[:return]||url(:data_entry)
          notice = 'All payments made succesfully'
          if(request.xhr?)
            render("<div class='notice'>#{notice}<div>", :layout => layout?)
          else
            redirect(return_url, :message => {:notice => notice})
          end
        else
          display [@errors, @center, @date]
        end
      else
        if params[:format] and API_SUPPORT_FORMAT.include?(params[:format])
          @weeksheet_rows = Weeksheet.get_center_weeksheet(@center,@date, @info) if @center
          display @weeksheet_rows
        elsif params[:format] and params[:format] == "pdf"
          generate_weeksheet_pdf(@center, @date)
          send_data(File.read("#{Merb.root}/public/pdfs/weeksheet_of_center_#{@center.id}_#{@date.strftime('%Y_%m_%d')}.pdf"),
                                    :filename => "#{Merb.root}/public/pdfs/weeksheet_of_center_#{@center.id}_#{@date.strftime('%Y_%m_%d')}.pdf")
        else
          render
        end
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
          mark_attendance
        end
        if @success and @errors.blank?
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
      @loan = Loan.get(payment[:loan_id])
      @client = @loan.client
      raise NotFound unless (@loan or @client)
      success = do_payment(payment)
      if success  # true if saved
        if params[:format] and API_SUPPORT_FORMAT.include?(params[:format])
          display @payment
        else
          redirect url(:data_entry), :message => {:notice => "Payment of #{@payment.id} has been registered"}
        end
      else
        if params[:format] and API_SUPPORT_FORMAT.include?(params[:format])
          display @payment
        else
          render :record
        end
      end
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
        @fees.errors.to_hash.each{|k,v| @payment.errors.add(k,v)}  if @fees
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
    

    def staff_collection_sheet
      
      @data = StaffMember.all(:active => true)
      render
    end


    private
    include DateParser
    # this function is called by by_center and by_staff_member
    def bulk_payments_and_disbursals
      @center = Center.get(params[:center_id]) || Center.first(:name => params[:center_id]) 
      @branch = @center.branch unless @center.nil?
      @clients = @center.clients(:fields => [:id, :name, :center_id, :client_group_id]) unless @center.nil?

      @staff = StaffMember.get(params[:payment][:received_by])
      @errors = []
      if params[:paid][:loan]
        params[:paid][:loan].keys.each do |k|
          @loan = Loan.get(k.to_i)
          @loan.history_disabled = true
          amounts = params[:paid][:loan][k.to_sym].to_f
          if amounts<=0
            @loan.update_history
            next
          end
          if params.key?(:payment_type) and params[:payment_type] == "fees"
            @success, @fees = @loan.pay_fees(amounts, @date, @staff, session.user)
            @fees.each{|f| @errors << f.errors unless f.errors.blank?}
          else
            style = params[:preclose_all].blank? ? params[:payment_style][k.to_sym].to_sym : :normal #if preclosing, use fee => int => prin style
            @type = params[:payment][:type]
            next if amounts<=0
            @success, @prin, @int, @fees = @loan.repay(amounts, session.user, @date, @staff, true, style)
            @errors << @prin.errors if (@prin and not @prin.errors.blank?)
            @errors << @int.errors if (@int and not @int.errors.blank? )
            @fees.each{|f| @errors << f.errors unless f.errors.blank?} if @fees
          end
          if @success 
            unless params[:preclose_all].blank?
              @loan.preclosed_on = @date; @loan.preclosed_by = @staff; 
              @loan.save
            end
            @loan.history_disabled = false
            @loan.already_updated  = false
            @loan.update_history(true)
          else
          end
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

    def mark_attendance
      return if not params or not params[:attendance] 
      params[:attendance].each do |client_id, status|
        client = Client.get(client_id)
        a = Attendance.first(:date => @date, :client_id => client_id, :center_id => client.center.id)
        if a
          a.update(:status => status)
        else
          a = Attendance.new(:date => @date, :client_id => client_id, :center_id => client.center.id, :status => status)
        end
        @errors << a.errors unless a.save
      end
    end
  end
end
