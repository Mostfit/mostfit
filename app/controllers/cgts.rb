class Cgts < Application
  # provides :xml, :yaml, :js
  before :get_context

  def index
    @cgts = @client_group.cgts
    @cgt = Cgt.new
    display @cgts
  end

  def show(id)
    @cgt = Cgt.get(id)
    raise NotFound unless @cgt
    display @cgt
  end

  def new
    only_provides :html
    @cgt = Cgt.new
    display @cgt
  end

  def edit(id)
    only_provides :html
    @cgt = Cgt.get(id)
    raise NotFound unless @cgt
    display @cgt
  end

  def create(cgt)
    @cgt = Cgt.new(cgt)
    if @cgt.save
      if params[:return] and not params[:return].blank?
        redirect params[:return], :message => {:notice => "Cgt was successfully created"}
      else
        redirect resource(@client_group, :cgts), :message => {:notice => "Cgt was successfully created"}
      end
    else
      message[:error] = "Cgt failed to be created"
      @cgts = @client_group.cgts
      if params[:return] and not params[:return].blank?
        redirect params[:return], :message => message
      else
        render :index
      end
    end
  end

  def update(id, cgt)
    @cgt = Cgt.get(id)
    raise NotFound unless @cgt
    if @cgt.update(cgt)
      if params[:return] and not params[:return].blank?
        redirect params[:return], :message => {:notice => "Cgt was successfully saved"}
      else
        redirect resource(@client_group), :message => {:notice => "Cgt was successfully saved"}
      end
    else
      if params[:return] and not params[:return].blank?
        redirect params[:return]
      else
        display @cgt, :edit
      end
    end
  end

  def destroy(id)
    @cgt = Cgt.get(id)
    raise NotFound unless @cgt
    if @cgt.destroy
      redirect resource(:cgts)
    else
      raise InternalServerError
    end
  end

  private
  def get_context
    @client_group = params[:client_group_id] ? ClientGroup.get(params[:client_group_id]) : nil
    raise NotFound unless @client_group
  end


end # Cgts
