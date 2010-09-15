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
  end
end
