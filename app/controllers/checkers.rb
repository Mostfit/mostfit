class Checkers < Application
  # provides :xml, :yaml, :js
  
  before :get_upload

  def index
    @checkers = @upload.checkers(:ok => false)
    display @checkers
  end

  def recheck
    @checkers = @upload.checkers(:ok => false)
    @checkers.each{|c| c.check}
    redirect resource(@upload, :checkers)
  end

  def show(id)
    @checker = Checker.get(id)
    raise NotFound unless @checker
    display @checker
  end

  def new
    only_provides :html
    @checker = Checker.new
    display @checker
  end

  def edit(id)
    only_provides :html
    @checker = Checker.get(id)
    raise NotFound unless @checker
    display @checker
  end

  def create(checker)
    @checker = Checker.new(checker)
    if @checker.save
      redirect resource(@checker), :message => {:notice => "Checker was successfully created"}
    else
      message[:error] = "Checker failed to be created"
      render :new
    end
  end

  def update(id, checker)
    @checker = Checker.get(id)
    raise NotFound unless @checker
    if @checker.update(checker)
       redirect resource(@checker)
    else
      display @checker, :edit
    end
  end

  def destroy(id)
    @checker = Checker.get(id)
    raise NotFound unless @checker
    if @checker.destroy
      redirect resource(:checkers)
    else
      raise InternalServerError
    end
  end

  private
  
  def get_upload
    @upload = Upload.get(params[:upload_id])
  end

end # Checkers
