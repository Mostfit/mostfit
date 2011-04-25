class Application < Merb::Controller
  before :ensure_authenticated
  before :ensure_password_fresh
  before :ensure_can_do
  before :insert_session_to_observer
  before :add_collections, :only => [:index, :show]
  
  @@controllers  = ["regions", "area", "branches", "centers", "clients", "loans", "payments", "staff_members", "funders", "portfolios", "funding_lines"]
  @@dependant_deletable_associations = ["history", "loan_history", "audit_trails", "attendances", "portfolio_loans", "postings", "credit_account_rules", "debit_account_rules", "center_meeting_days", "applicable_fees"]

  def ensure_password_fresh
    if session.key?(:change_password) and session[:change_password] and not params[:action] == "change_password"
      redirect url(:change_password)
    end
  end

  def insert_session_to_observer
    DataAccessObserver.insert_session(session.object_id)
  end

  def ensure_can_do
    @route = Merb::Router.match(request)
    unless session.user and session.user.can_access?(@route[1], params)
      raise NotPrivileged
    end
  end

  def ensure_admin
    unless (session.user and session.user.role == :admin)
      raise NotPrivileged
    end
  end

  def determine_layout
    return params[:layout] if params[:layout] and not params[:layout].blank?
  end

  def render_to_pdf(options = nil)
    data = render_to_string(options)
    pdf = PDF::HTMLDoc.new
    pdf.set_option :bodycolor, :white
    pdf.set_option :toc, false
    pdf.set_option :portrait, true
    pdf.set_option :links, false
    pdf.set_option :webpage, true
    pdf.set_option :left, '2cm'
    pdf.set_option :right, '2cm'
    pdf << data
    pdf.generate
  end

  def delete
    raise NotPrivileged unless session.user.admin?
    raise NotFound      unless params[:model] and params[:id]
    model    = Kernel.const_get(params[:model].camel_case.singularize)
    id       = params[:id]

    raise NotFound unless model.get(id)
    obj     = model.get(id)

    error =  ""
    flag, children_present = get_dependent_relationships(obj)

    if model==Loan and not obj.disbursal_date.nil?
      flag  = false
      error += " it has already been disbursed and "
    end

    if obj.respond_to?(:verified_by) and obj.verified_by
      flag = false
      error += "verified data cannot be deleted"
    end

      # if flag is still set to true delete the object
    if flag == true and obj.destroy
      # delete all the loan history
      LoanHistory.all(:loan_id => obj.id).destroy if model  == Loan or model.superclass == Loan or model.superclass.superclass == Loan
      Attendance.all(:client_id => obj.id).destroy if model == Client
      PortfolioLoan.all(:portfolio_id => obj.id).destroy if model == Portfolio
      Posting.all(:journal_id => obj.id).destroy if model == Journal

      if model == RuleBook
        CreditAccountRule.all(:rule_book_id => obj.id).destroy!
        DebitAccountRule.all(:rule_book_id => obj.id).destroy!
      end


      return_url = params[:return].split("/")[0..-3].join("/")
      redirect(return_url, :message => {:notice =>  "Deleted #{model} #{model.respond_to?(:name) ? model.name : ''} (id: #{id})"})
    else
      if model == ApplicableFee
        obj.destroy! #skip validations. they fail on the duplicate one
        redirect(params[:return], :message => {:notice =>  "Deleted #{model} #{model.respond_to?(:name) ? model.name : ''} (id: #{id})"})
      end

      # spitting out the error message
      error   = "Cannot delete #{model} (id: #{id}) because " + error
      error  += obj.errors.to_hash.values.flatten.join(" and ").downcase
      error  += " there are " if children_present.length > 0
      error  += children_present.collect{|k, v| 
        v==1 ? "#{v} #{k.singularize.gsub('_', ' ')}" : "#{v} #{k.gsub('_', ' ')}"
      }.join(" and ")
      error  += " under this #{model}" if children_present.length>0
      redirect(params[:return], :message => {:notice =>  "#{error}"})
    end    
  end

  private 
  def layout?
    return(request.xhr? ? false : :application)
  end
  
  def get_dependent_relationships(obj)
    flag  = true
    model =  obj.class
    # add child definitions to children; For loan model do not add history

    children = model.relationships.find_all{|x|
      if x[1].class==DataMapper::Associations::OneToMany::Relationship and not @@dependant_deletable_associations.include?(x[0])
        x[0]
      end
    }
   
    children_present = {}

    children.each{|x|
      relationship_method = x[0].to_sym
      unless obj.respond_to?(relationship_method)
        flag = false
        next
      end
      
      child_objects_count = obj.method(relationship_method).call.count
      if child_objects_count > 0        
        flag = false
        children_present[x[0]] = child_objects_count
      end
    }
    [flag, children_present]
  end

  def display_from_cache
    file = get_cached_filename
    return true unless File.exists?(file)
    return true if not File.mtime(file).to_date==Date.today
    throw :halt, render(File.read(file), :layout => false)
  end
  
  def store_to_cache
    file = get_cached_filename
    if not (File.exists?(file) and File.mtime(file).to_date==Date.today)
      File.open(file, "w"){|f|
        f.puts @body
      }
    end
  end
  
  def get_cached_filename
    hash = params.deep_clone
    dir = File.join(Merb.root, "public", hash.delete(:controller).to_s, hash.delete(:action).to_s)
    unless File.exists?(dir)
      FileUtils.mkdir_p(dir)
    end
    File.join(dir, (hash.empty? ? "index" : hash.collect{|k,v| "#{k}_#{v}"}))
  end

  def add_collections
    return unless session.user.role==:funder
    return unless @@controllers.include?(params[:controller])
    return if params[:controller] == "loans"
    @funder = Funder.first(:user_id => session.user.id)
    idx     = @@controllers.index(params[:controller])
    idx    += 1 if params[:action] != "index" and not (params[:controller] == "staff_members" or params[:controller] == "funding_lines")
    var     = @@controllers[idx]
    raise NotFound unless var
    instance_variable_set("@#{var}", @funder.send(var))
  end
end
