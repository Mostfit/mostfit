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
      @loan.interest_rate *= 100
      @loan_product = @loan.loan_product
      render
    end
  end
end
#     def create
#       klass, attrs = get_loan_and_attrs
#       attrs[:interest_rate] = attrs[:interest_rate].to_f / 100 if attrs[:interest_rate].to_f > 1
#       @loan = klass.new(attrs)
#       raise NotFound if not @loan.client  # should be known though hidden field
#       @loan_product = LoanProduct.is_valid(params[:loan_product_id])
#       @loan.loan_product_id = @loan_product.id 
#       @client = @loan.client
#       if @loan.save
#         if params[:format]=='xml'
#           display @loan, ""
#         else
#           redirect url(:enter_loans, :action => 'new'), :message => {:notice => "Loan '#{@loan.id}' was successfully created"}
#         end
#       else
#         @loan.interest_rate *= 100
#         params[:format]=='xml'? display(@loan) : render(:new)
#       end
#     end
#     def update
#       klass, attrs = get_loan_and_attrs
#       attrs[:interest_rate] = attrs[:interest_rate].to_f / 100 if attrs[:interest_rate].to_f > 0
#       @loan = klass.get(params[klass.to_s.snake_case.to_sym][:id])
#       raise NotFound unless @loan
#       @loan_product = @loan.loan_product
#       if @loan.update_attributes(attrs)
#         if params[:format]=='xml'
#           display @loan, ""
#         else
#           redirect url(:enter_loans, :action => 'new'), :message => {:notice => "Loan '#{@loan.id}' was successfully created"}
#         end
#       else
#         params[:format]=='xml'? display(@loan): render(:edit)
#       end
#     end


#     private
#     # the loan is not of type Loan of a derived type, therefor we cannot just assume its name..
#     # this method gets the loans type from a hidden field value and uses that to get the attrs
#     def get_loan_and_attrs   # FIXME: this is a code dup with the loans contoller
#       loan_key = params.keys.find { |x| x =~  /loan$/ }  # loan params have the key like 'a50_loan' or 'loan'
#       attrs = params[loan_key]
#       raise NotFound if not params[:loan_type]
#       klass = Kernel::const_get(params[:loan_type])
#       [klass, attrs]
#     end
