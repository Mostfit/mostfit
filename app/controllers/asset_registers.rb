class AssetRegisters < Application
  before :get_context, :exclude => ['redirect_to_show']
  provides :xml, :yaml, :js
  include DateParser

  def index
    if request.xhr? and params[:branch_id]
      @asset_registers = AssetRegister.all(:branch_id => params[:branch_id]).paginate(:page => params[:page], :per_page => 15, :order => [:issue_date.desc])
      display @asset_registers, :layout => layout?
    else
      @asset_registers = (@asset_registers || AssetRegister.all).paginate(:page => params[:page], :per_page => 15)
      display @asset_registers, :layout => layout?
    end
  end

  def show(id)
    @asset_register = AssetRegister.get(id)
    raise NotFound unless @asset_register
    display @asset_register, :layout => layout?
  end

  def new
    only_provides :html
    @asset_register = AssetRegister.new
    @branch = Branch.get(params[:branch_id]) if params and params.key?(:branch_id)
    display @asset_register, :layout => layout?
  end

  def edit(id)
    only_provides :html
    @asset_register = AssetRegister.get(id)
    raise NotFound unless @asset_register
    @branch = @asset_register.branch if @asset_register.branch_id
    display @asset_register, :layout => layout?
  end

  def create(asset_register)
    @asset_register = AssetRegister.new(asset_register)
    if @asset_register.save
      redirect(params[:return] ||resource(@asset_register.branch), :message => {:notice => "Asset entry was successfully entered"})
    else
      message[:error] = "Asset entry failed to be entered"
      render :new #error message will show                                                                                                                              
    end
  end

  def update(id, asset_register)
    @asset_register = AssetRegister.get(id)
    raise NotFound unless @asset_register
    if @asset_register.update(asset_register)
      redirect(params[:return] ||resource(@asset_register.branch), :message => {:notice => "Asset entry was successfully updated"})
    else
      display @asset_register, :edit
    end
  end

  def destroy(id)
    @asset_register = AssetRegister.get(id)
    raise NotFound unless @asset_register
    if @asset_register.destroy
      redirect(params[:return] ||resource(@asset_register.branch), :message => {:notice => "Asset entry was successfully deleted"})
    else
      raise InternalServerError
    end
  end

  def delete(id)
    edit(id)
  end

  def redirect_to_show(id) 
    raise NotFound unless @asset_register = AssetRegister.get(id)
    redirect resource(@asset_register)
  end

  private
  def get_context
    @branch = Branch.get(params[:branch_id]) if params.key?(:branch_id)
  end

end # AssetRegisters
