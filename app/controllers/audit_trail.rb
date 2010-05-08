class AuditTrails < Application
  def index
    model = params[:audit_for][:controller].singularize.capitalize
    if params[:audit_for].key?(:id)
      id=params[:audit_for][:id]
    elsif params[:audit_for][:controller]=="loans" and params[:audit_for].key?(:client_id)
      id=params[:audit_for][:client_id]
      model = "Client"
    end
    
    model = "Loan" if not ["Branch", "Center", "Loan", "Client", "Payment"].include?(model) and /Loan^/.match(model)    
      
    @trails = AuditTrail.all(:auditable_id => id, :auditable_type => model, 
                             :order => [:created_at.desc])
    partial "audit_trail/list", :layout => false
  end
end
