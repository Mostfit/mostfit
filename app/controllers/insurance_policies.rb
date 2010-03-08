class InsurancePolicies < Application
  # provides :xml, :yaml, :js
  before :get_context

  def index
    @insurance_policies = @client ? @client.insurance_policies : InsurancePolicy.all
    display @insurance_policies
  end

  def show(id)
    @insurance_policy ||= InsurancePolicy.get(id)
    raise NotFound unless @insurance_policy
    display @insurance_policy
  end

  def new
    only_provides :html
    @insurance_policy = InsurancePolicy.new
    display @insurance_policy
  end

  def edit(id)
    only_provides :html
    @insurance_policy ||= InsurancePolicy.get(id)
    raise NotFound unless @insurance_policy
    display @insurance_policy
  end

  def create(insurance_policy)
    @insurance_policy = InsurancePolicy.new(insurance_policy)
    @insurance_policy.client = @client
    @insurance_policy.status = Date.today > @insurance_policy.date_to ? :expired : :active
    if @insurance_policy.save
      redirect resource(@client, :insurance_policies), :message => {:notice => "Insurance Policy was successfully created"}
    else
      message[:error] = "Insurance Policy failed to be created"
      render :new
    end
  end

  def update(id, insurance_policy)
    @insurance_policy ||= InsurancePolicy.get(id)
    raise NotFound unless @insurance_policy
    if @insurance_policy.update(insurance_policy)
       redirect resource(@client, :insurance_policies)
    else
      display @insurance_policy, :edit
    end
  end

  def destroy(id)
    @insurance_policy ||= InsurancePolicy.get(id)
    raise NotFound unless @insurance_policy
    if @insurance_policy.destroy
      redirect resource(:insurance_policies)
    else
      raise InternalServerError
    end
  end

  private
  def get_context
    @client = Client.get(params[:client_id])
    if params[:id]
      @insurance_policy = InsurancePolicy.get(params[:id])
      @client = @insurance_policy.client
    end
    raise NotFound unless @client
  end

end # InsurancePolicies
