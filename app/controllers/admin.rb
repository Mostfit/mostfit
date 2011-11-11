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

  def data
    # towards some functions for assessing data quality and addressing these issues
    @stale_caches = CenterCache.all(:stale => true).aggregate(:branch_id, :center_id,:updated_at).map{|x| [[x[0],x[1]], x[2]]}.to_hash.deepen
    @loan_history_for_deleted_loans = LoanHistory.all(:loan_id => Loan.with_deleted{Loan.all(:deleted_at.not => nil)}.aggregate(:id))
    max_payment = Payment.all.aggregate(:loan_id, :created_at.max).to_hash
    max_loan = Loan.all.aggregate(:id, :updated_at).to_hash
    latest = (max_payment + max_loan).map{|k,v| [k,v.respond_to?(:max) ? v.max : v]}.to_hash
    @last_histories = LoanHistory.all.aggregate(:loan_id, :created_at).to_hash
    @stale_loan_histories = latest.select{|loan_id, updated_at| @last_histories[loan_id] ? @last_histories[loan_id] < updated_at : true}.to_hash
    render
  end
  
  def insurance
    @insurance_companies = InsuranceCompany.all
    @insurance_products  = InsuranceProduct.all
    render
  end
end
