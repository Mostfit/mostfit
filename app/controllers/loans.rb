class Loans < Application
  before :get_context, :exclude => ['redirect_to_show', 'approve', 'disburse', 'reject', 'write_off_reject', 'write_off_suggested', 'collection_sheet']
  provides :xml, :yaml, :js
  
  def index
    @loans = @loans || @client.loans
    display @loans
  end

  def latest
    @offset = params[:page].to_i -1
    @limit = 20
    @loans = Loan.all(:order => [:created_at.desc], :offset => @offset, :limit => 10)
    display @loans
  end

  def show(id)
    @option = params[:option] if params[:option]
    @loan = Loan.get(id)
    raise NotFound unless @loan
    @payments = @loan.payments(:order => [:received_on, :id])
    if params[:format] and API_SUPPORT_FORMAT.include?(params[:format])
      display [@loan, @payments]
    else
      display [@loan, @payments], 'payments/index'
    end
  end

  def new
    only_provides :html
    if params[:product_id] and @loan_product = LoanProduct.is_valid(params[:product_id])      
      @loan = Loan.new
      set_insurance_policy(@loan_product)
    end

    @loan_products = LoanProduct.valid if @loan.nil?
    display [@loan_types, @loan]
  end

  def create
    klass, attrs = get_loan_and_attrs
    attrs[:interest_rate] = attrs[:interest_rate].to_f / 100 if attrs[:interest_rate].to_f > 0
    @loan_product = LoanProduct.is_valid(params[:loan_product_id])
    raise BadRequest unless @loan_product
    @loan = klass.new(attrs)
    @loan.loan_product = @loan_product
    if @loan.save
      if params[:format] and API_SUPPORT_FORMAT.include?(params[:format])
        display @loan
      else
        if params[:return]
          redirect(params[:return], :message => {:notice => "Loan '#{@loan.id}' was successfully created"})
        else
          redirect resource(@branch, @center, @client), :message => {:notice => "Loan '#{@loan.id}' was successfully created"}
        end
      end
    else
      if params[:format] and API_SUPPORT_FORMAT.include?(params[:format])
        display @loan
      else
        set_insurance_policy(@loan_product)
        @loan.interest_rate *= 100
        render :new # error messages will be shown
      end
    end
  end
  def bulk_create
    klass, attrs = get_loan_and_attrs
    attrs[:interest_rate] = attrs[:interest_rate].to_f / 100 if attrs[:interest_rate].to_f > 0
    loan_product = LoanProduct.is_valid(params[:loan_product_id])
    raise BadRequest unless loan_product
    loans = statuses = []

    # create loans for all the clients
    Loan.transaction do |t|
      params[:client_ids].each{|client_id|
        attrs[:client_id] = client_id.to_i
        @loan = klass.new(attrs)
        @loan.loan_product  = loan_product
        loans.push(@loan)
      }
      statuses = loans.map{|l| l.save}
      t.rollback if statuses.include?(false)
    end

    if not statuses.include?(false)
      if params[:return]
        redirect(params[:return], :message => {:notice => "'#{statuses.count}' loans were successfully created"})
      else
        redirect(url(:data_entry), :message => {:notice => "'#{statuses.count}' loans were successfully created"})
      end
    else      
      # on error recreate form with errors
      @loan_product  = @loan.loan_product if @loan
      @clients = Client.all(:id => params[:client_ids])
      display [], "data_entry/loans/bulk_form"
    end
  end


  def levy_fees(id)
    @loan = Loan.get(id)
    raise NotFound unless @loan
    @loan.levy_fees(false)
    redirect url_for_loan(@loan) + "#misc", :message => {:notice => 'Fees levied'}
  end

  def bulk_restore_payments(id)
  end


  def edit(id)
    only_provides :html
    @loan = Loan.get(id)
    @loan_product =  @loan.loan_product
    raise NotFound unless @loan

    set_insurance_policy(@loan_product)
    disallow_updation_of_verified_loans
    @loan.interest_rate*=100
    display @loan
  end

  def update(id)
    klass, attrs = get_loan_and_attrs
    attrs[:interest_rate] = attrs[:interest_rate].to_f / 100 if attrs[:interest_rate].to_f > 0
    attrs[:occupation_id] = nil if attrs[:occupation_id] == ''
    @loan = klass.get(id)
    raise NotFound unless @loan
    disallow_updation_of_verified_loans

    # if an attached insurance policy then create or update insurance policy
    if attrs[:insurance_policy]
      @insurance_policy = @loan.insurance_policy || Insurance.new
      @insurance_policy.client = @loan.client
      @insurance_policy.attributes = attrs.delete(:insurance_policy)
    end
    @loan.attributes = attrs
    @loan_product = @loan.loan_product
    @loan.insurance_policy = @insurance_policy if @loan_product.linked_to_insurance and @insurance_policy   

    if @loan.save or @loan.errors.length==0
      if params[:return]
        redirect(params[:return], :message => {:notice => "Loan '#{@loan.id}' has been edited"})
      else
        redirect url_for_loan(@loan), :message => {:notice => "Loan '#{@loan.id}' has been edited"}
      end
    else
      @loan.interest_rate*=100
      display @loan, :edit  # error messages will be shown
    end
  end

  def delete(id)
    edit(id)  # so far these are the same
  end

  def destroy(id)
    @loan = Loan.get(id)
    disallow_updation_of_verified_loans
    raise NotFound unless @loan
    if @loan.destroy
      redirect resource(@branch, @center, @client), :message => {:notice => "Loan '#{@loan.id}' has been deleted"}
    else
      raise InternalServerError
    end
  end

  # this redirects to the proper url, used from the router
  def redirect_to_show(id)
    raise NotFound unless @loan = Loan.get(id)
    @branch, @center, @client = @loan.client.center.branch, @loan.client.center, @loan.client
    redirect url_for_loan(@loan)
  end

  def disburse
    @date = params[:date] ? Date.parse(params[:date]) : Date.today
    hash   = {:scheduled_disbursal_date.lte => @date, :disbursal_date => nil, :approved_on.not => nil, :rejected_on => nil}
    if request.method == :get
      @loans = get_loans(hash)
      render
    else
      @loans = get_loans(hash, false)
      loan_ids = @loans.aggregate(:id)
      @errors = []
      cheque_numbers = params[:loans].select{|k,v| v[:disbursed?]!= "on" and not v[:cheque_number].blank?}.to_hash
      #save cheque numbers
      cheque_numbers.keys.each do |id|
        loan = Loan.get(id.to_i)
        loan.cheque_number  = params[:loans][id][:cheque_number] and params[:loans][id][:cheque_number].to_i>0 ? params[:loans][id][:cheque_number] : nil
        loan.save
      end

      # disburse loans
      disbursal_loans = params[:loans].select{|k,v| v[:disbursed?] == "on"}.to_hash
      disbursal_loans.keys.each do |id|        
        loan = Loan.get(id.to_i)
        next unless loan_ids.include?(loan.id)
        loan.disbursal_date = params[:loans][id][:disbursal_date]
        loan.cheque_number  = params[:loans][id][:cheque_number] and params[:loans][id][:cheque_number].to_i>0 ? params[:loans][id][:cheque_number] : nil
        loan.scheduled_first_payment_date = params[:loans][id][:scheduled_first_payment_date] if params[:loans][id][:scheduled_first_payment_date]
        loan.amount         = params[:loans][id][:amount]
        loan.disbursed_by   = StaffMember.get(params[:loans][id][:disbursed_by_staff_id])
        @errors << loan.errors if not loan.save
      end
      rurl = (params[:return]||url(:data_entry))
      if @errors.blank?
        redirect rurl, :message => {:notice => "#{disbursal_loans.size} loans disbursed. #{params[:loans].size - disbursal_loans.size} loans not disbursed."}
      else
        redirect rurl, :message => {:notice => "#{disbursal_loans.size} loans disbursed. #{params[:loans].size - disbursal_loans.size} loans not disbursed."}
      end
    end
  end

  def approve
    if request.method == :get
      if params[:center_id]
        @loans_to_approve = @loan.all("client.center" => Center.get(params[:center_id]))
      else
        @loans_to_approve = get_loans({:approved_on => nil, :rejected_on => nil})
      end
      @loans_to_approve.each {|l| l.clear_cache}
      @clients =  @loans_to_approve.clients
      render
    else
      @errors = []
      loans = params[:loans].select{|k,v| v[:approved?] == "on"}.to_hash
      @loans_to_approve = get_loans({:approved_on => nil, :rejected_on => nil}, false)

      loans.keys.each do |id|
        loan = Loan.get(id)
        next unless @loans_to_approve.include?(loan)
        params[:loans][id].delete("approved?")        
        params[:loans][id][:amount] = params[:loans][id][:amount_sanctioned]
        unless loan.update(params[:loans][id])
          @errors << loan.errors
        end
      end

      if @errors.blank?
        redirect(params[:return]||"/data_entry", :message => {:notice => 'loans approved'})
      else
        @loans_to_approve = Loan.all(:id.in => loans.keys)
        @clients =  @loans_to_approve.clients
        render
      end
    end
  end


  def reject
    if request.method == :post
      @errors = []
      @loans = params[:loans].select{|k,v| v[:approved?] == "on" or v[:disbursed?] == "on"}.to_hash
      @loans.keys.each do |id|
        loan = Loan.get(id)
        params[:loans][id].delete("approved?")        
        loan.rejected_on = Date.today
        loan.rejected_by_staff_id = params[:loans][id][:approved_by_staff_id]||params[:loans][id][:disbursed_by_staff_id]
        @errors << loan.errors unless loan.save
      end
      if @errors.blank?
        redirect(params[:return]||"/data_entry", :message => {:notice => 'loans rejected'})
      else
        @loans_to_approve = Loan.all(:id.in => @loans.keys)
        @clients =  @loans_to_approve.clients
        render
      end
    end
  end

  def write_off_reject
    if request.method == :post
      @errors = []
      @loans = params[:loans].select{|k,v| v[:write_off?] == "on"}.to_hash
      @loans.keys.each do |id|
        loan = Loan.get(id)
        params[:loans][id].delete("write_off?")
        loan.write_off_rejected_on = params[:loans][id][:written_off_on]
        loan.write_off_rejected_by_staff_id = params[:loans][id][:written_off_by_staff_id]
        @errors << loan.errors unless loan.save_self
      end
      if @errors.blank?
        redirect(params[:return]||"/data_entry", :message => {:notice => 'loan write off rejected'})
      else
        @loans_to_write_off = Loan.all(:id.in => @loans.keys)
        @clients =  @loans_to_write_off.clients
        render
      end
    end
  end

  def write_off(id)
    if request.method == :post 
      @loan = Loan.get(id)
      raise NotFound unless @loan
      hash = params[@loan.class.to_s.snake_case]
      if @loan.write_off(hash[:written_off_on], hash[:written_off_by_staff_id])
        redirect(resource(@branch, @center, @client, @loan), :message => {:notice => "Loan was successfully written off"})
      else
        message[:error] = "Please select staff member who writes off the loan and date on which it is written off"
        @payments = @loan.payments(:order => [:received_on, :id])
        display [@loan, @payments], 'payments/index'
      end
    end
  end

  def reverse_write_off(id)
    @loan = Loan.get(id)
    raise NotFound unless @loan
    @loan.written_off_by = @loan.suggested_written_off_by_staff_id = @loan.write_off_rejected_by_staff_id = nil
    @loan.written_off_on = @loan.suggested_written_off_on = @loan.write_off_rejected_on = nil
    msg = {}
    if @loan.save
      @loan.update_history
      @loan.update_loan_cache
      msg = {:notice => "Loan was successfully reversed from written off"}
    else
      msg = {:error => "Loan could not be reversed because #{@loan.errors.values.join(',')}"}
    end
    redirect(resource(@branch, @center, @client, @loan) + "#misc", :message => msg) 
  end
  
  def write_off_suggested
    if request.method == :get
      if params[:center_id]
        @loans_to_write_off = @loan.all("client.center" => Center.get(params[:center_id]))
      else
        @loans_to_write_off = Loan.all(:write_off_rejected_on => nil, :written_off_on => nil, 
                                       :suggested_written_off_on.lte => Date.today).paginate(:page => params[:page], :per_page => 10)
      end
      @loans_to_write_off.each {|l| l.clear_cache}
      @clients =  @loans_to_write_off.clients
      render
    else
      if request.method == :post
        @errors = []
        params[:loans].map{|loan_id, data|
          if (data["write_off?"] == "on")
            loan = Loan.get(loan_id)
            next unless loan
            unless loan = loan.write_off(data[:written_off_on], data[:written_off_by_staff_id])
              @errors << loan.errors
            end
          end
        }
        if @errors.length == 0
          redirect("/data_entry", :message => {:notice => "Loan was successfully written off"})
        else
          render
        end
      end
    end
  end
    
  def suggest_write_off(id)
    if request.method == :post
      @loan = Loan.get(id)
      raise NotFound unless @loan
      hash = params[@loan.class.to_s.snake_case]
      @loan.suggested_written_off_on = hash[:suggested_written_off_on]
      @loan.suggested_written_off_by_staff_id = hash[:suggested_written_off_by_staff_id]
      client = @loan.client
      center = client.center
      branch = center.branch
      if @loan.save_self
        redirect(resource(branch, center, client), :message => {:notice => "Loan was successfully suggested for written off"})
      else
        redirect(resource(branch, center, client), :message => {:notice => "Unable to suggest loan for write off"})
      end
    end
  end
  
  def misc(id)
    @loan = Loan.get(id)
    @applicable_fee = ApplicableFee.new(:applicable_type => 'Loan', :applicable_id => @loan.id)
    request.xhr? ? render(:layout => false) : render
  end
  
  def update_utilization(id)
    @loan =  Loan.get(id)    
    @loan.history_disabled = true
    if params[:loan] and params[:loan][:loan_utilization_id] and not params[:loan][:loan_utilization_id].blank?
      @loan.loan_utilization_id = params[:loan][:loan_utilization_id]
    else
      @loan.loan_utilization_id = nil
    end
    
    if @loan.save_self
      request.xhr? ? render("Saved loan utilization", :layout => false) : redirect(resource(@loan))
    else
      request.xhr? ? render(@loan.errors.to_a.map{|x| x.join(":")}.join(", "), :layout => false) : render(resource(@loan, :edit))
    end
  end

  def repair(id)
    loan = Loan.get(id)
    raise NotFound unless loan
    loan.update_history_bulk_insert
    redirect url_for_loan(loan), :message => {:notice => "LoanHistory updated!"}
  end

  def reallocate(id)
    @loan = Loan.get(id)
    raise NotFound unless @loan
    status, @payments = @loan.reallocate(params[:style].to_sym, session.user)
    if status
      redirect url_for_loan(@loan), :message => {:notice => "Loan payments succesfully reallocated"}
    else
      render 
    end
  end
    
  def diagnose(id)
    @loan = Loan.get(id)
    raise NotFound unless @loan
    display [@loan], :layout => false
  end

  def repayment_sheet(id)
    @loan = Loan.get(id)
    raise NotFound unless @loan
    file = @loan.generate_loan_schedule
    if file
      send_data(file.to_s, :filename => "repayment_schedule_loan_#{@loan.id}.pdf")
    else
      redirect resource(@loan) 
    end
  end

  def prepay(id)
    @loan = Loan.get(id)
    raise NotFound unless @loan
    if request.method == :get
      display @loan, :layout => layout?
    else
      staff = StaffMember.get(params[:received_by])
      raise ArgumentError.new("No staff member selected") unless staff
      raise ArgumentError.new("No applicable fee for penalty") if (params[:fee].blank? and (not params[:penalty_amount].blank?))
      @date = Date.parse(params[:date])

      # make new applicable fee for the penalty
      pmt_params = {:received_by => staff, :loan_id => @loan.id, :created_by => session.user, :client => @loan.client, :received_on => @date}
      unless params[:fee].blank?
        if params[:penalty_amount].to_i > 0
          af = ApplicableFee.new(:amount => params[:penalty_amount], :applicable_type => 'Loan', :applicable_id => @loan.id, :fee_id => params[:fee], :applicable_on => @date)
          af.save
          penalty_pmt =  Payment.new({:amount => params[:penalty_amount].to_f, :fee_id => params[:fee], :comment => af.fee.name, :type => :fees}.merge(pmt_params))
        end
        if params[:fees].blank?
          fee_payments = []
        else
          fee_payments = params[:fees].map do |k,v| 
            fee = Fee.get(k)
            Payment.new({:amount => v.to_f, :fee => fee, :comment => fee.name, :type => :fees}.merge(pmt_params))
          end.compact
        end
      end
      ppmt = Payment.new({:amount => params[:principal].to_f, :type => :principal}.merge(pmt_params))
      ipmt = Payment.new({:amount => params[:interest].to_f, :type => :interest}.merge(pmt_params))
      
      pmts = ((fee_payments || []) + [penalty_pmt, ppmt, ipmt].compact).select{|p| p.amount > 0}

      if pmts.blank?
        success = true
      else
        success, @p, @i, @f = @loan.make_payments(pmts)
      end
            
      if success
        if params[:writeoff]
          @loan.preclosed_on = @date
          @loan.preclosed_by = staff
        end
        @loan.save
        @loan.history_disabled = false
        # update history after reloading object
        Loan.first(:id => @loan.id).reload.update_history(true)
        redirect url_for_loan(@loan), :message => {:notice => "Loan has been prepayed"} 
      else
        af.destroy! if af
        render :layout => layout?
      end
    end
  end

  private
  def get_context
    if params[:id]
      @loan = Loan.get(params[:id])
      raise NotFound unless @loan
      @client = @loan.client
      @center = @client.center
      @branch = @center.branch
    else
      if params[:client_id]
        @client = Client.get(params[:client_id])
      elsif params[:client_ids]
        @clients = Client.all(:id => params[:client_id])
      end
      @center = Center.get(params[:center_id])
      @branch = Branch.get(params[:branch_id])
      raise NotFound unless @branch and @center
      raise NotFound unless (@client or @clients)
    end
  end

  # the loan is not of type Loan of a derived type, therefor we cannot just assume its name..
  # this method gets the loans type from a hidden field value and uses that to get the attrs
  def get_loan_and_attrs   # FIXME: this is a code dup with data_entry/loans
    if params[:id] and not params[:id].blank?
      loan =  Loan.get(params[:id])      
      loan_product = loan.loan_product
      attrs = params[loan.discriminator.to_s.snake_case.to_sym] || {}
      klass = loan.class
    else
      loan_product = LoanProduct.get(params[:loan_product_id])
      attrs = (params[loan_product.loan_type_string.snake_case.to_sym] || params[:loan]).dup
      raise NotFound if not params[:loan_type]
      klass = Kernel::const_get(params[:loan_type])
    end
    attrs[:client_id] ||= params[:client_id] if params[:client_id]
    attrs[:client] = Client.get(attrs.delete(:client_id))
    attrs[:loan_product] = LoanProduct.get(attrs.delete(:loan_product_id)) if attrs[:loan_product_id]
    attrs[:insurance_policy] = params[:insurance_policy] if params[:insurance_policy]
    attrs[:repayment_style_id] ||= loan_product.repayment_style.id
    [klass, attrs]
  end

  def disallow_updation_of_verified_loans
    raise NotChangeable if @loan.verified_by_user_id and not session.user.admin?
  end

  def collection_sheet
    render
  end
  
  # set the loans which are accessible by the user
  def get_loans(hash, paginate = true)
    if staff = session.user.staff_member
      hash["client.center.branch_id"] = [staff.branches, staff.areas.branches, staff.regions.areas.branches].flatten.map{|x| x.id}
      Loan.all(hash)
    else
      paginate ? Loan.all(hash).paginate(:page => params[:page], :per_page => 10)  : Loan.all(hash)
    end
  end

  def set_insurance_policy(loan_product)
    if @loan_product.linked_to_insurance
      @insurance_policy = @loan.insurance_policy || InsurancePolicy.new
      @insurance_policy.client = @client
    end
  end
end # Loans
