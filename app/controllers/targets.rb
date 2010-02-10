class Targets < Application
  provides :xml, :yaml, :json
  def index
    @targets = Target.all(:order => [:deadline])
    display @targets
  end
  
  def all(id)
    @objects = Kernel.const_get(id.camelcase).all(:order => [:name])
    display @objects
  end

  def show(id)
    @target = Target.get(id)
    raise NotFound unless @target
    display @target
  end

  def new
    only_provides :html
    @target = Target.new
    display @target
  end

  def edit(id)
    only_provides :html
    @target = Target.get(id)
    raise NotFound unless @target
    @objects = Kernel.const_get(@target.attached_to.to_s.camelcase).all(:order => [:name])
    display @target
  end

  def create(target)
    @target = Target.new(target)
    if @target.save
      redirect resource(:targets), :message => {:notice => "Target was successfully created"}
    else
      @objects = Kernel.const_get(@target.attached_to.to_s.camelcase).all(:order => [:name])
      message[:error] = "Target failed to be created"
      render :new
    end
  end

  def update(id, target)
    @target = Target.get(id)
    raise NotFound unless @target
    if @target.update(target)
       redirect resource(:targets)
    else
      @objects = Kernel.const_get(@target.attached_to.to_s.camelcase).all(:order => [:name])
      display @target, :edit
    end
  end

  def destroy(id)
    @target = Target.get(id)
    raise NotFound unless @target
    if @target.destroy
      redirect resource(:targets)
    else
      raise InternalServerError
    end
  end
end # Targets
