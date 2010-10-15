class AuditTrails < Application
  def index
    raise NotFound if not params[:audit_for] 
    model = params[:audit_for][:controller].singularize.capitalize
    if params[:audit_for].key?(:id)
      id=params[:audit_for][:id]
    elsif params[:audit_for][:controller]=="loans" and params[:audit_for].key?(:client_id)
      id=params[:audit_for][:client_id]
      model = "Client"
    elsif params[:audit_for][:controller]=="payments" and params[:audit_for].key?(:loan_id) and not params[:audit_for].key?(:id)
      id=params[:audit_for][:loan_id]
      model = "Loan"
    end

    model = "Loan" if not ["Branch", "Center", "Loan", "Client", "Payment"].include?(model) and /Loan^/.match(model)   
    if model=="Loan"
      loan  = Loan.get(id)
      model = ["Loan", loan.class.to_s]
    end
    @trails = AuditTrail.all(:auditable_id => id, :auditable_type => model, 
                             :order => [:created_at.desc])
    partial "audit_trails/list", :layout => false
  end

  def show(id)
    date = params[:date] ? Date.parse(params[:date]) : Date.today
    hash = {:created_at.gte => date, :created_at.lt => date + 1}
    hash[:user_id] = User.get(params[:user]).id if params[:user] and not params[:user].blank?
    hash[:auditable_type] = params[:auditable_type] if params[:auditable_type]
    @trails = AuditTrail.all(hash)
    render
  end
end
