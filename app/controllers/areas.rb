class Areas < Application
  provides :xml
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

  def branches
    if params[:id]
      area = Area.get(params[:id])
      next unless area
      return("<option value=''>Select branch</option>"+area.branches(:order => [:name]).map{|br| "<option value=#{br.id}>#{br.name}</option>"}.join)
    end
  end

  private
  def get_region
    @region = params[:region_id] ? Region.get(params[:region_id]) : nil
  end

end # Areas
