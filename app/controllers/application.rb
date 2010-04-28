class Application < Merb::Controller
  before :ensure_authenticated
  before :ensure_can_do
  before :insert_session_to_observer

  def insert_session_to_observer
    DataAccessObserver.insert_session(session.object_id)
  end

  def ensure_can_do
    @route = Merb::Router.match(request)
    raise NotPrivileged unless session.user.can_access?(@route[1], params)
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

    # if flag is still set to true delete the object
    if flag == true and obj.destroy
      # delete all the loan history
      LoanHistory.all(:loan_id => obj.id).destroy if model==Loan      
      return_url = params[:return].split("/")[0..-3].join("/")
      redirect(return_url, :message => {:notice =>  "Deleted #{model} #{model.respond_to?(:name) ? model.name : ''} (id: #{id})"})
    else
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
      x[0] if x[1].class==DataMapper::Associations::OneToMany::Relationship and not x[0]=="history" and not x[0]=="audit_trails"
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
end
