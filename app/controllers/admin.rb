class Admin < Application

  def index
    render
  end

  def upload    
    if params[:file]
      file      = Upload.new(params[:file][:filename])      
      file.move(params[:file][:tempfile].path)
      Process.fork{
        `rake 'mostfit:upload[#{file.directory}, #{file.filename}]'`
      }
      redirect "/admin/upload_status/#{file.directory}"
    else
      render
    end
  end

  def upload_status        
    render
  end
  
  def edit
    @mfi  = Mfi.new($globals ? $globals[:mfi_details] : {})
    render
  end
  
  def update(mfi)
    @mfi  = Mfi.new(mfi)
    if @mfi.valid?
      @mfi.save
      redirect(url(:admin), :message => {:notice => "MFI details has been saved"})
    else
      render :edit
    end
  end
end
