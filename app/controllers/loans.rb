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
    @loan = Loan.get(id)
    raise NotFound unless @loan
    @payments = @loan.payments(:order => [:received_on, :id])
    display [@loan, @payments], 'payments/index'
  end

  def new
    only_provides :html
    if params[:product_id] and @loan_product = LoanProduct.is_valid(params[:product_id])
      if Loan.descendants.map{|x| x.to_s}.include?(@loan_product.loan_type)
        klass = Kernel::const_get(@loan_product.loan_type)
        @loan = klass.new
      end
    end
    @loan_products = LoanProduct.valid if @loan.nil?
    display [@loan_types, @loan]
  end

  def create
    klass, attrs = get_loan_and_attrs
    attrs[:interest_rate] = attrs[:interest_rate].to_f / 100 if attrs[:interest_rate].to_f > 0
    @loan = klass.new(attrs)
    raise NotFound if not @loan.client  # should be known though hidden field
    @loan_product = LoanProduct.is_valid(params[:loan_product_id])
    @loan.loan_product_id = @loan_product.id     
    @loan.amount          = @loan.amount_applied_for
    if @loan.save
      if params[:return]
        redirect(params[:return], :message => {:notice => "Loan '#{@loan.id}' was successfully created"})
      else
        redirect resource(@branch, @center, @client, :loans), :message => {:notice => "Loan '#{@loan.id}' was successfully created"}
      end
    else
      @loan.interest_rate *= 100
      render :new # error messages will be shown
    end
  end

  def edit(id)
    only_provides :html
    @loan = Loan.get(id)
    @loan_product =  @loan.loan_product
    raise NotFound unless @loan
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
    @loan.attributes = attrs
    @loan_product = @loan.loan_product

    if @loan.save or @loan.errors.length==0
      if params[:return]
        redirect(params[:return], :message => {:notice => "Loan '#{@loan.id}' has been edited"})
      else
        redirect resource(@branch, @center, @client, :loans), :message => {:notice => "Loan '#{@loan.id}' has been edited"}
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
      redirect resource(@branch, @center, @client, :loans), :message => {:notice => "Loan '#{@loan.id}' has been deleted"}
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
    if request.method == :get
      @loans = Loan.all(:scheduled_disbursal_date.lte => @date, :disbursal_date => nil, :approved_on.not => nil, :rejected_on => nil).paginate(:page => params[:page], :per_page => 10)
      render
    else
      @errors = []
      cheque_numbers = params[:loans].select{|k,v| v[:disbursed?]!= "on" and not v[:cheque_number].blank?}.to_hash
      #save cheque numbers
      cheque_numbers.keys.each do |id|
        loan = Loan.get(id)
        loan.cheque_number  = params[:loans][id][:cheque_number] and params[:loans][id][:cheque_number].to_i>0 ? params[:loans][id][:cheque_number] : nil
        loan.save
      end

      # disburse loans
      loans = params[:loans].select{|k,v| v[:disbursed?] == "on"}.to_hash
      loans.keys.each do |id|
        loan = Loan.get(id)
        loan.disbursal_date = params[:loans][id][:disbursal_date]
        loan.cheque_number  = params[:loans][id][:cheque_number] and params[:loans][id][:cheque_number].to_i>0 ? params[:loans][id][:cheque_number] : nil
        loan.scheduled_first_payment_date = params[:loans][id][:scheduled_first_payment_date] if params[:loans][id][:scheduled_first_payment_date]
        loan.amount         = params[:loans][id][:amount]
        loan.disbursed_by   = StaffMember.get(params[:loans][id][:disbursed_by_staff_id])
        @errors << loan.errors if not loan.save
      end
      if @errors.blank?
        redirect params[:return]||url(:data_entry),{:message => {:notice => "#{loans.size} loans disbursed. #{params[:loans].size - loans.size} loans not disbursed."}}
      else
        @loans  ||= Loan.all(:id => loans.keys)
        render
      end
    end
  end

  def approve
    debugger
    if request.method == :get
      if params[:center_id]
        @loans_to_approve = @loan.all("client.center" => Center.get(params[:center_id]))
      else
        @loans_to_approve = Loan.all(:approved_on => nil, :rejected_on => nil).paginate(:page => params[:page], :per_page => 10)
      end
      @loans_to_approve.each {|l| l.clear_cache}
      @clients =  @loans_to_approve.clients
      render
    else
      @errors = []
      @loans = params[:loans].select{|k,v| v[:approved?] == "on"}.to_hash
      @loans.keys.each do |id|
        loan = Loan.get(id)
        params[:loans][id].delete("approved?")        
        params[:loans][id][:amount] = params[:loans][id][:amount_sanctioned]
        loan.update(params[:loans][id])
        @errors << loan.errors unless loan.save
      end
      if @errors.blank?
        redirect(params[:return]||"/data_entry", :message => {:notice => 'loans approved'})
      else
        @loans_to_approve = Loan.all(:id.in => @loans.keys)
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
        redirect(resource(@branch, @center, @client), :message => {:notice => "Loan was successfully written off"})
      else
        render
      end
    end
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
    request.xhr? ? render(:layout => false) : render
  end
  
  def update_utilization(id)
    @loan =  Loan.get(id)    
    if @loan.update!(:loan_utilization_id => params[:loan][:loan_utilization_id])
      request.xhr? ? render("Saved loan utilization", :layout => false) : redirect(resource(@loan))
    else
      request.xhr? ? render(@loan.errors.to_a.map{|x| x.join(":")}.join(", "), :layout => false, :status => 400) : render(resource(@loan, :edit))
    end
  end

  def repair(id)
    loan = Loan.get(id)
    raise NotFound unless loan
    loan.update_history
    redirect("/loans/#{loan.id}")
  end


  # def make_loan_utilization
    
  #   render
  # end

  private
  def get_context
    if params[:id]
      @loan = Loan.get(params[:id])
      raise NotFound unless @loan
      @client = @loan.client
      @center = @client.center
      @branch = @center.branch
    else
      @client = Client.get(params[:client_id])
      @center = Center.get(params[:center_id])
      @branch = Branch.get(params[:branch_id])
      raise NotFound unless @branch and @center and @client
    end
  end

  # the loan is not of type Loan of a derived type, therefor we cannot just assume its name..
  # this method gets the loans type from a hidden field value and uses that to get the attrs
  def get_loan_and_attrs   # FIXME: this is a code dup with data_entry/loans
    loan_product = LoanProduct.get(params[:loan_product_id])
    attrs = params[loan_product.loan_type.snake_case.to_sym]
    attrs[:client_id]=params[:client_id] if params[:client_id]
    raise NotFound if not params[:loan_type]
    klass = Kernel::const_get(params[:loan_type])
    [klass, attrs]
  end

  def disallow_updation_of_verified_loans
    raise NotPrivileged if @loan.verified_by_user_id and not session.user.admin?
  end

  def collection_sheet
    render
  end
  
end # Loans
