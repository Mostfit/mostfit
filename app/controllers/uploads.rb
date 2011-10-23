class Uploads < Application

  before do
    raise NotAcceptable unless Mfi.first.system_state == :migration
  end

  def index
    hash = session.user.admin? ? {} : {:user => session.user}
    @uploads = Upload.all(hash.merge(:order => [:updated_at]))
    display @uploads
  end

  def new
    @upload = Upload.new
    display @upload
  end
  
  def create
    debugger
    erase = params.has_key?(:erase)
    if params[:file] and params[:file][:filename] and params[:file][:tempfile]
      file      = Upload.make(params.merge(:user => session.user))
    else
      render
    end
  end

  def continue(id)
    debugger
    @upload = Upload.get(id)
    @upload.continue
    redirect resource(:uploads)
  end

  
end
