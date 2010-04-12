class AuditTrails < Application
  def index
    @trails = AuditTrail.all(:auditable_id => params[:audit_for][:id], :auditable_type => params[:audit_for][:controller].singularize.capitalize, 
                             :order => [:created_at.desc])
    partial "audit_trail/list", :layout => false
  end
end
