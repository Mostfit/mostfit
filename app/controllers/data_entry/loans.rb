module DataEntry

class Loans < DataEntry::Controller
  provides :html, :xml
  def new
    debugger
    if params[:client_id]
      @client = Client.get(params[:client_id])
      if params[:loan_type]
        if Loan.descendants.map{|x| x.to_s}.include? params[:loan_type]
          begin
            klass = Kernel::const_get(params[:loan_type])
            @loan = klass.new
          end
#          @loan = (params[:loan] and params[:loan][:id]) ? Loan.get(params[:loan][:id]) : (@loan or Loan.new)
        end
      else
        @loan_types = Loan.descendants if @loan.nil?
        display [@loan_types, @loan, @client]
      end
    end
    render
  end

  def create
    klass, attrs = get_loan_and_attrs
    @loan = klass.new(attrs)
    raise NotFound if not @loan.client  # should be known though hidden field
    @client = @loan.client
    if @loan.save
      if params[:format]=='xml'
        display @loan, ""
      else
        redirect url(:enter_loans, :action => 'new'), :message => {:notice => "Loan '#{@loan.id}' was successfully created"}
      end
    else
      params[:format]=='xml'? display(@loan) : render(:new)
    end
  end

  def edit
    @loan = (params[:loan] and params[:loan][:id]) ? Loan.get(params[:loan][:id]) : Loan.new
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
