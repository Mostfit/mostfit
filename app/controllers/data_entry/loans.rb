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

    def edit
      @loan = (params[:loan] and params[:loan][:id]) ? Loan.get(params[:loan][:id]) : Loan.new
      @client = @loan.client(:fields => [:id, :name, :center_id, :client_group_id])
      @loan.interest_rate *= 100 if @loan.interest_rate
      @loan_product = @loan.loan_product
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
        @loans = params[:loans].select{|k,v| v[:approved?] == "on"}.to_hash
        @loans.keys.each do |id|
          loan = Loan.get(id)
          params[:loans][id].delete("approved?")      
          params[:loans][id][:loan_utilization_id] = params[:loans][id][:loan_utilization_id]
          loan.update(params[:loans][id])
          loan.history_disabled = true
          loan.save
        end
        if @errors.blank?
          redirect(params[:return]||"/data_entry", :message => {:notice => 'loans utilised'})
        else
          @loans_to_utilize = Loan.all(:id.in => @loans.keys)
          @clients =  @loans_to_utilize.clients
          render
        end
      end
    end
    
  end
end
