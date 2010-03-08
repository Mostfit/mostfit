class Grts < Application
  # provides :xml, :yaml, :js

  def index
    @grts = Grt.all
    display @grts
  end

  def show(id)
    @grt = Grt.get(id)
    raise NotFound unless @grt
    display @grt
  end

  def new
    only_provides :html
    @grt = Grt.new
    display @grt
  end

  def edit(id)
    only_provides :html
    @grt = Grt.get(id)
    raise NotFound unless @grt
    display @grt
  end

  def create(grt)
    @grt = Grt.new(grt)
    if @grt.save
      redirect resource(@grt), :message => {:notice => "Grt was successfully created"}
    else
      message[:error] = "Grt failed to be created"
      render :new
    end
  end

  def update(id, grt)
    @grt = Grt.get(id)
    raise NotFound unless @grt
    if @grt.update(grt)
       redirect resource(@grt)
    else
      display @grt, :edit
    end
  end

  def destroy(id)
    @grt = Grt.get(id)
    raise NotFound unless @grt
    if @grt.destroy
      redirect resource(:grts)
    else
      raise InternalServerError
    end
  end

end # Grts
