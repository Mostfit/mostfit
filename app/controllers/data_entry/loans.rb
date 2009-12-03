module DataEntry

class Loans < DataEntry::Controller
  provides :html, :xml
  def new
    if params[:client_id]
      @client = Client.get(params[:client_id]) || Client.first(:name => params[:client_id]) || Client.first(:reference => params[:client_id])
      if params[:product_id] and @loan_product = LoanProduct.is_valid(params[:product_id])
        if Loan.descendants.map{|x| x.to_s}.include?(@loan_product.loan_type)
          klass = Kernel::const_get(@loan_product.loan_type)
          @loan = klass.new
        end
      end
    end
    @loan_types    = Loan.descendants if @loan.nil?
    @loan_products = LoanProduct.valid if @loan.nil?
#    display [@loan_types, @loan_products, @loan, @client]
    render
  end

  def create
    klass, attrs = get_loan_and_attrs
    attrs[:interest_rate] = attrs[:interest_rate].to_f / 100 if attrs[:interest_rate].to_f > 1
    @loan = klass.new(attrs)
    raise NotFound if not @loan.client  # should be known though hidden field
    @loan_product = LoanProduct.is_valid(params[:loan_product_id])
    @loan.loan_product_id = @loan_product.id 
    @client = @loan.client
    if @loan.save
      if params[:format]=='xml'
        display @loan, ""
      else
        redirect url(:enter_loans, :action => 'new'), :message => {:notice => "Loan '#{@loan.id}' was successfully created"}
      end
    else
      @loan.interest_rate *= 100
      params[:format]=='xml'? display(@loan) : render(:new)
    end
  end

  def edit
    @loan = (params[:loan] and params[:loan][:id]) ? Loan.get(params[:loan][:id]) : Loan.new
    @loan_product = @loan.loan_product
    render
  end

  def update
    klass, attrs = get_loan_and_attrs
    @loan = klass.get(params[klass.to_s.snake_case.to_sym][:id])
    raise NotFound unless @loan
    if @loan.update_attributes(attrs)
      if params[:format]=='xml'
            display @loan, ""
      else
        redirect url(:enter_loans, :action => 'new'), :message => {:notice => "Loan '#{@loan.id}' was successfully created"}
      end
    else
      params[:format]=='xml'? display(@loan): render(:edit)
    end
  end

  def disburse
    @date = params[:date] ? Date.parse(params[:date]) : Date.today
    @loans = Loan.all(:scheduled_disbursal_date.lte => @date, :disbursal_date => nil).select{|l| l.status == :approved}
    if request.method == :get
      render
    else
      @errors = []
      loans = params[:loans].select{|k,v| v[:disbursed?] == "on"}.to_hash
      loans.keys.each do |id|
        loan = Loan.get(id)
        params[:loans][id].delete("disbursed?")
        loan.update_attributes(params[:loans][id])
        @errors << loan.errors if not loan.save
      end
      if @errors.blank?
        redirect url(:data_entry), {:message => {:notice => "#{loans.size} loans disbursed. #{params[:loans].size - loans.size} loans not disbursed."}}
      else
        render
      end
    end
  end

  def approve
    if request.method == :get
      if params[:center_id]
        @loans_to_approve = @loan.all("client.center" => Center.get(params[:center_id]))
      else
        @loans_to_approve = Loan.all(:approved_on => nil)
      end
      @loans_to_approve.each {|l| l.clear_cache}
      render
    else
      @errors = []
      @loans = params[:loans].select{|k,v| v[:approved?] == "on"}.to_hash
      @loans.keys.each do |id|
        loan = Loan.get(id)
        params[:loans][id].delete("approved?")
        loan.update_attributes(params[:loans][id])
        @errors << loan.errors unless loan.save
      end
      if @errors.blank?
        redirect "/data_entry", :message => {:notice => 'loans approved'}
      else
        @loans_to_approve = Loan.all(:id.in => @loans.keys)
        render
      end
    end
  end

  private
  # the loan is not of type Loan of a derived type, therefor we cannot just assume its name..
  # this method gets the loans type from a hidden field value and uses that to get the attrs
  def get_loan_and_attrs   # FIXME: this is a code dup with the loans contoller
    loan_key = params.keys.find { |x| x =~  /loan$/ }  # loan params have the key like 'a50_loan' or 'loan'
    attrs = params[loan_key]
    raise NotFound if not params[:loan_type]
    klass = Kernel::const_get(params[:loan_type])
    [klass, attrs]
  end
end

end
