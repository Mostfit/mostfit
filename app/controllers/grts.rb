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
      message = {:notice => "GRT was successfully created"}
      if params[:return] and not params[:return].blank?
        redirect params[:return], :message => message
      else
        redirect resource(@client_group, :grts), :message => message
      end
    else
      message = {:error => "GRT failed to be created"}
      @grts = @client_group.grts
      if params[:return] and not params[:return].blank?
        redirect params[:return], :message => message
      else
        render :index
      end
    end
  end

  def update(id, grt)
    @grt = Grt.get(id)
    @grt.client_group = @client_group
    raise NotFound unless @grt
    if @grt.update(grt)
      message = {:notice => "GRT was successfully saved"}
      if params[:return] and not params[:return].blank?
        redirect params[:return], :message => message
      else
        redirect resource(@client_group, :grts)
      end     
    else
      message = {:notice => "GRT was failed to be saved"}      
      if params[:return] and not params[:return].blank?
        redirect params[:return], :message => message
      else
        display @grt, :edit
      end      
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
