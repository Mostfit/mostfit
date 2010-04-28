class Regions < Application
  # provides :xml, :yaml, :js
  include DateParser

  def index
    @regions = Region.all
    display @regions
  end

  def show(id)
    @region = Region.get(id)
    raise NotFound unless @region
    display @region
  end
  
  # Show more info about this region
  def moreinfo(id)
    @render_form = true
    @render_form = false if params[:_target_]
    @from_date = params[:from_date] ? parse_date(params[:from_date]) : Date.min_date
    @to_date   = params[:to_date]   ? parse_date(params[:to_date])   : Date.today
    allow_nil  = (params[:from_date] or params[:to_date]) ? false : true
    @region = Region.get(id)
    raise NotFound unless @region

    if allow_nil
      @areas         = @region.areas
      @branches      = @areas.branches
      @centers       = @branches.centers(:fields => [:id, :branch_id])
      @clients       = @centers.clients(:fields => [:id, :center_id])
    else
      @areas         = @region.areas(:creation_date.lte => @to_date, :creation_date.gte => @from_date)
      @branches      = @areas.branches(:creation_date.lte => @to_date, :creation_date.gte => @from_date)
      @centers       = @branches.centers(:fields => [:id, :branch_id], :creation_date.lte => @to_date, :creation_date.gte => @from_date)
      @clients       = @centers.clients(:fields => [:id, :center_id], :date_joined.lte => @to_date, :date_joined.gte => @from_date)
    end

    @centers_count = @centers.count
    @groups_count  = (@centers_count>0) ? @centers.client_groups(:fields => [:id]).count : 0
    @clients_count = (@centers_count>0) ? @clients.count : 0
    @payments      = Payment.collected_for(@region, @from_date, @to_date)
    @fees          = Fee.collected_for(@region, @from_date, @to_date)
    @loan_disbursed= LoanHistory.amount_disbursed_for(@region, @from_date, @to_date)
    @loan_data     = LoanHistory.sum_outstanding_for(@region, @from_date, @to_date)
    @defaulted     = LoanHistory.defaulted_loan_info_for(@region, @to_date)
    render :file => 'branches/moreinfo', :layout => false
  end

  def new
    only_provides :html
    @region = Region.new
    display @region
  end

  def edit(id)
    only_provides :html
    @region = Region.get(id)
    raise NotFound unless @region
    display @region
  end

  def create(region)
    @region = Region.new(region)
    if @region.save
      redirect resource(:regions), :message => {:notice => "Region was successfully created"}
    else
      message[:error] = "Region failed to be created"
      render :new
    end
  end

  def update(id, region)
    @region = Region.get(id)
    raise NotFound unless @region
    if @region.update(region)
       redirect resource(@region)
    else
      display @region, :edit
    end
  end
end # Regions
