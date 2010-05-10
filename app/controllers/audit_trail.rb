class AuditTrails < Application
  def index
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
    partial "audit_trail/list", :layout => false
  end
end
