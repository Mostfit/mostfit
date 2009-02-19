class Funders < Application
  # provides :xml, :yaml, :js

  def index
    @funders = Funder.all
    display @funders
  end

  def show(id)
    @funder = Funder.get(id)
    raise NotFound unless @funder
    display @funder
  end

  def new
    only_provides :html
    @funder = Funder.new
    display @funder
  end

  def edit(id)
    only_provides :html
    @funder = Funder.get(id)
    raise NotFound unless @funder
    display @funder
  end

  def create(funder)
    @funder = Funder.new(funder)
    if @funder.save
      redirect resource(@funder), :message => {:notice => "Funder was successfully created"}
    else
      message[:error] = "Funder failed to be created"
      render :new
    end
  end

  def update(id, funder)
    @funder = Funder.get(id)
    raise NotFound unless @funder
    if @funder.update_attributes(funder)
       redirect resource(@funder)
    else
      display @funder, :edit
    end
  end

  def destroy(id)
    @funder = Funder.get(id)
    raise NotFound unless @funder
    if @funder.destroy
      redirect resource(:funders)
    else
      raise InternalServerError
    end
  end

end # Funders
