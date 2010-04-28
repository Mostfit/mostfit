class Areas < Application
  # provides :xml, :yaml, :js
  include DateParser
  before :get_region

  def index
    @areas = @region ? @region.areas : Area.all
    if @region
      render "regions/show"
    else
      display @areas
    end
  end

  def show(id)
    @area = Area.get(id)
    raise NotFound unless @area
    display @area
  end

  # Show more info about this area
  def moreinfo(id)
    @render_form = true
    @render_form = false if params[:_target_]
    @from_date = params[:from_date] ? parse_date(params[:from_date]) : Date.min_date
    @to_date   = params[:to_date]   ? parse_date(params[:to_date])   : Date.today
    allow_nil  = (params[:from_date] or params[:to_date]) ? false : true
    @area = Area.get(id)
    raise NotFound unless @area

    if allow_nil
      @branches      = @area.branches
      @centers       = @branches.centers(:fields => [:id, :branch_id])
      @clients       = @centers.clients(:fields => [:id, :center_id])
    else
      @branches      = @area.branches(:creation_date.lte => @to_date, :creation_date.gte => @from_date)
      @centers       = @branches.centers(:fields => [:id, :branch_id], :creation_date.lte => @to_date, :creation_date.gte => @from_date)
      @clients       = @centers.clients(:fields => [:id, :center_id], :date_joined.lte => @to_date, :date_joined.gte => @from_date)
    end

    @centers_count = @centers.count
    @groups_count  = (@centers_count>0) ? @centers.client_groups(:fields => [:id]).count : 0
    @clients_count = (@centers_count>0) ? @clients.count : 0
    @payments      = Payment.collected_for(@area, @from_date, @to_date)
    @fees          = Fee.collected_for(@area, @from_date, @to_date)
    @loan_disbursed= LoanHistory.amount_disbursed_for(@area, @from_date, @to_date)
    @loan_data     = LoanHistory.sum_outstanding_for(@area, @from_date, @to_date)
    @defaulted     = LoanHistory.defaulted_loan_info_for(@area, @to_date)
    render :file => 'branches/moreinfo', :layout => false
  end

  def new
    only_provides :html
    @area = Area.new
    display @area
  end

  def edit(id)
    only_provides :html
    @area = Area.get(id)
    raise NotFound unless @area
    display @area
  end

  def create(area)
    @area = Area.new(area)
    if @area.save
      redirect resource(@area), :message => {:notice => "Area was successfully created"}
    else
      message[:error] = "Area failed to be created"
      render :new
    end
  end

  def update(id, area)
    @area = Area.get(id)
    raise NotFound unless @area
    if @area.update(area)
       redirect resource(@area)
    else
      display @area, :edit
    end
  end

  def destroy(id)
    @area = Area.get(id)
    raise NotFound unless @area
    if @area.destroy
      redirect resource(:areas)
    else
      raise InternalServerError
    end
  end

  private
  def get_region
    @region = params[:region_id] ? Region.get(params[:region_id]) : nil
  end

end # Areas
