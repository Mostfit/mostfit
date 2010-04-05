class Documents < Application
  before :get_parent, :only => [:index, :new, :edit, :create]
  # provides :xml, :yaml, :js
  def list
    @documents = Document.all(:parent_id => params[:parent_id], :parent_model => Mfi)
    render :index
  end

  def index
    @documents = Document.all(:parent_id => params[:parent_id], :parent_model => Kernel.const_get(params[:parent_model]))
    display @documents, :layout => false
  end

  def show(id)
    @document = Document.get(id)
    raise NotFound unless @document
    display @document
  end

  def new
    only_provides :html
    @document = Document.new
    display @document, :layout => false
  end

  def edit(id)
    only_provides :html
    @document = Document.get(id)
    raise NotFound unless @document
    display @document, :layout => false
  end

  def create(document)
    @document = Document.new(document)
    @document.parent_model = @parent.class
    @document.parent_id    = @parent.id
    if @document.save
      redirect(resource(@document.parent)+"#documents", :message => {:notice => "Document was successfully created"})
    else
      message[:error] = "Document failed to be created"
      render :new
    end
  end

  def update(id, document)
    @document = Document.get(id)
    raise NotFound unless @document
    if @document.update(document)
       redirect resource(@document.parent)+"#documents"
    else
      display @parent
    end
  end

  def destroy(id)
    @document = Document.get(id)
    raise NotFound unless @document
    if @document.destroy
      redirect resource(:documents)
    else
      raise InternalServerError
    end
  end

private
  def get_parent
    @parent = Kernel.const_get(params[:parent_model]).get(params[:parent_id])
  end
end # Documents
