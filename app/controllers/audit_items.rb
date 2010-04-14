class AuditItems < Application
  # provides :xml, :yaml, :js

  def index
    if (params[:id] and params[:model])
      if params[:status]
        @audit_items = AuditItem.all(:status => params[:status].to_sym,:audited_model => params[:model].camel_case, :audited_id => params[:id])
      else 
        @audit_items = AuditItem.all(:audited_model => params[:model], :audited_id => params[:id])
      end
    else
      @audit_items = AuditItem.all
    end
    if request.xhr?
      partial "audit_items/index"
    else
      display @audit_items
    end
  end

  def show(id)
    @audit_item = AuditItem.get(id)
    raise NotFound unless @audit_item
    display @audit_item
  end

  def new
    only_provides :html
    @audit_item = AuditItem.new
    display @audit_item
  end

  def edit(id)
    only_provides :html
    @audit_item = AuditItem.get(id)
    raise NotFound unless @audit_item
    display @audit_item
  end

  def create(audit_item)
    @audit_item = AuditItem.new(audit_item)
    if @audit_item.save
      redirect resource(@audit_item), :message => {:notice => "AuditItem was successfully created"}
    else
      message[:error] = "AuditItem failed to be created"
      render :new
    end
  end

  def update(id, audit_item)
    @audit_item = AuditItem.get(id)
    raise NotFound unless @audit_item
    if @audit_item.update(audit_item)
       redirect resource(@audit_item)
    else
      display @audit_item, :edit
    end
  end

  def destroy(id)
    @audit_item = AuditItem.get(id)
    raise NotFound unless @audit_item
    if @audit_item.destroy
      redirect resource(:audit_items)
    else
      raise InternalServerError
    end
  end

end # AuditItems
