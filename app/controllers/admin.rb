class Admin < Application

  def index
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
    @loans = DirtyLoan.pending if params[:show_all]
    render
  end

  def clear_loan
    DirtyLoan.clear(params[:id])
    render "done", :layout => false
  end

  def clear_loans
    DirtyLoan.send(:class_variable_set,"@@poke_thread",true)
    DirtyLoan.start_thread
    redirect url(:controller => :admin, :action => :index), :message => {:notice => "Started clearing the queue"}
  end

  def toggle_queue_processing
    pt = DirtyLoan.send(:class_variable_get,"@@poke_thread")
    queue_state = pt ? "Running" : "Stopped"
    DirtyLoan.send(:class_variable_set,"@@poke_thread", (not pt))
    queue_state = (not pt) ? "Running" : "Stopped"
    DirtyLoan.start_thread unless pt
    redirect url(:controller => :admin, :action => :index), :message => {:notice => "Queue #{queue_state}"}
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
