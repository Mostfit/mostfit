class AuditTrails < Application
  PER_PAGE = 20

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
    @obj    = Kernel.const_get(model).get(id)

    if model=="Loan"
      model = ["Loan", @obj.class.to_s]
    end
    @trails = AuditTrail.all(:auditable_id => id, :auditable_type => model, :order => [:created_at.desc])
    partial "audit_trails/list", :layout => false
  end

  def show(id)
    from_date = params[:from_date] ? Date.parse(params[:from_date]) : Date.today
    to_date = params[:to_date] ? Date.parse(params[:to_date]) : Date.today

    hash = {:created_at.gte => from_date, :created_at.lt => to_date + 1}
    hash[:action] = params[:change_action] if params[:change_action] and not params[:change_action].blank?
    hash[:user_id] = User.get(params[:user]).id if params[:user] and not params[:user].blank?

    if params[:auditable_type] and not params[:auditable_type].blank?
      hash[:auditable_type] = params[:auditable_type]
      model = Kernel.const_get(params[:auditable_type])
      @properties = Searches.new({}).send(:get_properties_for, model).map{|x| x.to_sym}

      if params[:col] and not params[:col].blank? and @properties and @properties.include?(params[:col].to_sym) and model
        @col = if model.properties.map{|x| x.name}.include?(params[:col].to_sym)
                 params[:col].to_sym
               elsif model.relationships.keys.include?(params[:col]) and model.relationships[params[:col]].child_key
                 model.relationships[params[:col]].child_key.first.name
               else
                 nil
               end
      end
    end

    @trails = AuditTrail.all(hash)
    page = (params[:page]||1).to_i
    @offset = (page-1)*PER_PAGE

    if @col
      @trails = @trails.reject{|trail|
        not trail.changes.reduce({}){|s,x| s+=x}.keys.include?(@col)
      }
      @length = @trails.length
      @trails = @trails[@offset..(page-1)*PER_PAGE + PER_PAGE - 1]
    else
      @length = AuditTrail.all(hash).count
      @trails = @trails.all(:offset => @offset, :limit => PER_PAGE)
    end
  
    render
  end
end
