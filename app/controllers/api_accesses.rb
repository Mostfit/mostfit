class ApiAccesses < Application
  # provides :xml, :yaml, :js

  def index
    @api_accesses = ApiAccess.all
    display @api_accesses
  end

  def show(id)
    @api_access = ApiAccess.get(id)
    raise NotFound unless @api_access
    display @api_access
  end

  def new
    only_provides :html
    @api_access = ApiAccess.new
    display @api_access
  end

  def edit(id)
    only_provides :html
    @api_access = ApiAccess.get(id)
    raise NotFound unless @api_access
    display @api_access
  end

  def create(api_access)
    @api_access = ApiAccess.new(api_access)
    @api_access.origin = UUID.generate
    if @api_access.save
      redirect resource(@api_access), :message => {:notice => "ApiAccess was successfully created"}
    else
      message[:error] = "ApiAccess failed to be created"
      render :new
    end
  end

  def update(id, api_access)
    @api_access = ApiAccess.get(id)
    raise NotFound unless @api_access
    if @api_access.update(api_access)
       redirect resource(@api_access)
    else
      display @api_access, :edit
    end
  end

  def destroy(id)
    @api_access = ApiAccess.get(id)
    raise NotFound unless @api_access
    if @api_access.destroy
      redirect resource(:api_accesses)
    else
      raise InternalServerError
    end
  end

end # ApiAccesses
