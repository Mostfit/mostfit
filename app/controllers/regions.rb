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
