class Admin < Application

  def index
    render
  end

  def upload    
    if params[:file]
      file      = Upload.new(params[:file][:filename])      
      file.move(params[:file][:tempfile].path)
      Process.fork{
        `rake 'db:upload[#{file.directory}, #{file.filename}]'`
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
      $globals ||= {}
      $globals[:mfi_details] = @mfi.attributes
      File.open(File.join(Merb.root, "config", "mfi.yml"), "w"){|f|
        f.puts @mfi.to_yaml
      }
      redirect(url(:admin), :message => {:notice => "MFI details has been saved"})
    else
      render :edit
    end
  end
end
