module DataEntry
  class Loans < DataEntry::Controller
    provides :html, :xml

    def new
      if params[:client_id]
        @client = Client.get(params[:client_id]) || Client.first(:name => params[:client_id]) || Client.first(:reference => params[:client_id])
        raise NotFound unless @client
        @center = @client.center

        if params[:product_id] and @loan_product = LoanProduct.is_valid(params[:product_id])
          @loan = Loan.new
          set_insurance_policy
        end
      end
      @loan_types    = Loan.descendants if @loan.nil?
      @loan_products = LoanProduct.valid if @loan.nil?
      #    display [@loan_types, @loan_products, @loan, @client]
      render
    end

    def edit
      @loan = (params[:loan] and params[:loan][:id]) ? Loan.get(params[:loan][:id]) : Loan.new
      raise NotFound unless @loan

      unless @loan.new?
        @client = @loan.client(:fields => [:id, :name, :center_id, :client_group_id])
        raise NotFound unless @client
        
        @center = @client.center
        raise NotFound unless @center
        
        @loan.interest_rate *= 100 if @loan.interest_rate
        @loan_product = @loan.loan_product
        set_insurance_policy
      end

      render
    end

    def staff_disbursement_sheet
      @data = StaffMember.all(:active => true)
      render
    end
    # def make_loan_utilization
    #   @loans_to_utilize = Loan.all(:loan_utilization_id => nil, :id.lt => 30)
    #   render
    # end

    def make_loan_utilization
      if request.method == :get
        if params[:center_id]
          @loans_to_utilize = @loan.all("client.center" => Center.get(params[:center_id]), :disbursal_date.lte => (Date.today - 28))
        else
          @loans_to_utilize = Loan.all(:disbursal_date.lte => (Date.today - 28)).paginate(:page => params[:page], :per_page => 10)
        end
        @loans_to_utilize.each {|l| l.clear_cache}
        @clients =  @loans_to_utilize.clients
        render
      else
        @errors = []
        loans = params[:loans].select{|k,v| v[:approved?] == "on"}.to_hash
        loans.keys.each do |id|
          loan = Loan.get(id)
          params[:loans][id].delete("approved?")      
          loan.history_disabled = true
          loan.already_updated  = true
          next if params[:loans][id].blank?
          loan.loan_utilization_id = params[:loans][id][:loan_utilization_id]
          unless loan.save_self
            @errors << false
          end
        end
        if @errors.blank?
          redirect(params[:return]||"/data_entry", :message => {:notice => 'loans utilization data saved'})
        else
          @loans_to_utilize = Loan.all(:id.in => loans.keys)
          @clients =  @loans_to_utilize.clients
          render
        end
      end
    end

    # action to bulk create loans with same paramters for an entire center
    def bulk_form
      # read the params into nice variables
      sc = params[:clients].map{|k,v| k if v[:chosen]}.compact if params[:clients]   # nice to be able to say "if @selected_clients" 
      @selected_clients = sc.blank? ? nil : sc                                       # instead of "unless @selected_clients.blank?"
      @center = Center.get(params[:center_id])
      @clients = @center.clients(:active => true, :order => [:client_group_id, :name]) if @center

      # find center and clients

      if not params[:query] and not params[:center_id] and @selected_clients.blank? # no idea about anything. 
        # ask which center
        @url = url(:action => :bulk_form)
        display([], "centers/search")
      elsif params[:query] and @selected_clients.blank? # query is there? good. no clients? 
        # ask about clients
        @center = Center.get(params[:query]) || Center.first(:code => params[:query]) || Center.first(:name => params[:query])
        raise NotFound unless @center
        @clients = @center.clients(:active => true, :order => [:client_group_id, :name])
        display([@center, @clients], "data_entry/loans/bulk_form")
        
      elsif params[:loan] 
        if @selected_clients
          # ok, we have enough to start making the loans
          @loans = []
          @selected_clients.each do |client_id|
            params[:clients][client_id].delete(:chosen)
            l = Loan.new(params[:loan].merge(params[:clients][client_id]).merge(:client_id => client_id))
            l.set_loan_product_parameters
            @loans.push(l)
          end
          Loan.transaction do |t|
            r = @loans.map{|l| l.save}
            if r.include?(false)
              t.rollback 
            else
              redirect resource(@center), :message => {:notice => "all loans added succesfully"}
            end
          end
        end
        render
      elsif params.key?(:center_id)
        @center = Center.get(params[:center_id])
        # get list of clients
        @clients = @center.clients(:active => true, :order => [:client_group_id, :name])
        message[:error] = ""
        message[:error] += "Please select at least one client." if not params[:client_ids] or params[:client_ids].blank?
        message[:error] += "Please select at loan product." if not params[:loan_product_id] or params[:loan_product_id].blank?
        render 
      end
    end
    
    def bulk_update_funding_line
      if request.method == :get
        @loans = Loan.all(:funding_line => nil).paginate(:page => params[:page], :per_page => 20)
        display @loans
      else
        @results = {}
        @loans = Loan.all(:id => params[:loan].keys)
        @loans.each do |loan| 
          loan.funding_line_id = params[:loan][loan.id.to_s].to_i unless params[:loan][loan.id.to_s].blank?
          loan.history_disabled = true
          @results[loan] = loan.save
        end
        @loans = Loan.all(:funding_line => nil).paginate(:page => params[:page], :per_page => 20)
        if @loans.count > 0
          render
        else
          c = @results.select{|k,v| v}.count
          redirect url(:data_entry), :message => {:notice => "#{c} Funding Lines updated succesfully"}
        end
      end
    end
    


    private
    def set_insurance_policy
      if @loan_product and @loan_product.linked_to_insurance
        @insurance_policy = InsurancePolicy.new
        @insurance_policy.client = @client if @client
      end
    end
  end
end

