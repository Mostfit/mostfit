class Comments < Application
  # provides :xml, :yaml, :js
  before :get_context

  def index
    @comments = Comment.all(:parent_model => @parent_model, :parent_id => @parent_id)
    if request.xhr?
      partial "comments/index", :object => @parent
    else
      display @comments
    end
  end

  def show(id)
    @comment = Comment.get(id)
    raise NotFound unless @comment
    display @comment
  end

  def new
    only_provides :html
    @comment = Comment.new
    display @comment
  end

  def edit(id)
    only_provides :html
    @comment = Comment.get(id)
    raise NotFound unless @comment
    display @comment
  end

  def create(comment)
    @comment = Comment.new(comment)
    if @comment.save
      if request.xhr?
        partial "comments/index", :object => @parent
      else
        redirect resource(@parent), :message => {:notice => "Comment was successfully created"}
      end
    else
      message[:error] = "Comment failed to be created"
      render :new
    end
  end

  def update(id, comment)
    @comment = Comment.get(id)
    raise NotFound unless @comment
    if @comment.update(comment)
       redirect resource(@comment)
    else
      display @comment, :edit
    end
  end

  def destroy(id)
    @comment = Comment.get(id)
    raise NotFound unless @comment
    if @comment.destroy
      redirect resource(:comments)
    else
      raise InternalServerError
    end
  end

  private
  
  def get_context
    uri = request.env["HTTP_REFERER"].split("/")
    @parent_model = uri[-2].singular.camel_case
    @parent_id = uri[-1]
    @parent = Kernel.const_get(@parent_model).get(@parent_id)
    raise NotAcceptable unless (@parent)
    params[:comment].merge!(:parent_model => @parent_model,
                           :parent_id => @parent_id, 
                           :user => session.user) if params[:comment]
  end
end # Comments
