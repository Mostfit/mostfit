class Grts < Application
  # provides :xml, :yaml, :js
  before :get_context

  def index
    @grts = @client_group.grts
    @grt = Grt.new
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
    @grt.client_group = @client_group
    if @grt.save
      redirect resource(@client_group, :grts), :message => {:notice => "GRT was created succesfully"}
    else
      message[:error] = "Cgt failed to be created"
      @grts = @client_group.grts
      render :index
    end
  end

  def update(id, grt)
    @grt = Grt.get(id)
    @grt.client_group = @client_group
    raise NotFound unless @grt
    if @grt.update(grt)
      redirect resource(:grts)
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

  private
  def get_context
    @client_group = params[:client_group_id] ? ClientGroup.get(params[:client_group_id]) : nil
    raise NotFound unless @client_group
  end

end # Grts
