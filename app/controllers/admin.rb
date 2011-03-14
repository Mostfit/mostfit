class Admin < Application

  def index
    render
  end

  def upload 
    data = params[:erase]
    if params[:file] and params[:file][:filename] and params[:file][:tempfile]
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
    @mfi  = Mfi.first
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

  def download
    @files = []
    if File.exists?(File.join(Merb.root, DUMP_FOLDER))
      (Dir.entries(File.join(Merb.root, DUMP_FOLDER)) - [".", ".."]).sort.reverse.each{|file|
        @files << file
      }
    end
    render
  end

  def download_dump(file)
    if file and File.exists?(File.join(Merb.root, DUMP_FOLDER, file))
      send_data(File.open(File.join(Merb.root, DUMP_FOLDER, file)), :filename => file, :type => "gzip")
    end
  end

  def dirty_loans
    @loans = DirtyLoan.pending
    render
  end

  def clear_loan
    DirtyLoan.clear(params[:id])
    render "done", :layout => false
  end

  def proxy_logon
    raise NotFound unless Merb.env=="development"    
    if session.user.role == :admin and params[:user_id] and user = User.get(params[:user_id])
      session.user = user
      redirect resource(:branches)
    else
      raise NotFound
    end
  end
  
  def insurance
    @insurance_companies = InsuranceCompany.all
    @insurance_products  = InsuranceProduct.all
    render
  end
end
