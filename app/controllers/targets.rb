class Targets < Application
  provides :xml, :yaml, :json
  before :get_target_type_attached, :only => [:bulk_entry_new, :bulk_entry_create]

  def index
    @targets = (@targets || Target.all).paginate(:page => params[:page], :per_page => 20, :order => [:deadline])
    display @targets
  end
  
  def all(id)
    @objects = Kernel.const_get(id.camelcase).all(:order => [:name])
    display @objects
  end

  def show(id)
    @target = Target.get(id)
    raise NotFound unless @target
    display @target
  end

  def new
    only_provides :html
    @target = Target.new
    display @target
  end
  
  def bulk_entry_new
    if @target_type and @attached_to and @target_of
      set_targets
    end
    render
  end

  def bulk_entry_create
    raise NotAllowed unless (@target_type and @attached_to and @target_of)
    targets = []
    params[:target].each{|obj_id, months|      
      months.each{|year_month, target|
        target = target.to_i
        next unless target > 0
        year, month = year_month.split("_").map{|x| x.to_i}
        start_date = Date.new(year, month, 1)
        end_date   = Date.new(year, month, -1)
        targets << Target.create(:target_value => target, :deadline => end_date, :start_date => start_date, :attached_to => @attached_to,
                                 :attached_id => obj_id, :start_value => 0, :target_type => @target_type, :target_of => @target_of)
      }
    }
    if targets.map{|t| t.errors.blank?}.include?(false)
      set_targets
      targets.each{|target|
        @targets ||= {}
        @targets[target.attached_id] ||= {}
        @targets[target.attached_id][target.start_date] ||= {}
        @targets[target.attached_id][target.start_date] = [target]
      }
      render :bulk_entry_new
    else
      redirect url(:action => :bulk_entry_new, :target_type => @target_type, :attached_to => @attached_to, :target_of => @target_of), :message => {:notice => "Targets were successfully created"}
    end
  end

  def edit(id)
    only_provides :html
    @target = Target.get(id)
    raise NotFound unless @target
    @objects = Kernel.const_get(@target.attached_to.to_s.camelcase).all(:order => [:name])
    display @target
  end

  def create(target)
    @target = Target.new(target)
    if @target.save
      redirect resource(:targets), :message => {:notice => "Target was successfully created"}
    else
      @objects = Kernel.const_get(@target.attached_to.to_s.camelcase).all(:order => [:name])
      message[:error] = "Target failed to be created"
      render :new
    end
  end

  def update(id, target)
    @target = Target.get(id)
    raise NotFound unless @target
    if @target.update(target)
       redirect resource(:targets)
    else
      @objects = Kernel.const_get(@target.attached_to.to_s.camelcase).all(:order => [:name])
      display @target, :edit
    end
  end

  def destroy(id)
    @target = Target.get(id)
    raise NotFound unless @target
    if @target.destroy
      redirect resource(:targets)
    else
      raise InternalServerError
    end
  end

  private
  def get_target_type_attached    
    @target_type  =  params[:target_type].to_sym if params.key?(:target_type) and not params[:target_type].blank?      and Target::TargetType.include?(params[:target_type].to_sym)
    @attached_to  =  params[:attached_to].to_sym if params.key?(:attached_to) and not params[:attached_to].blank?      and Target::ValidAttaches.include?(params[:attached_to].to_sym)
    @target_of    =  params[:target_of].to_sym   if params.key?(:target_of)   and not params[:target_of].blank?        and Target::TargetOf.include?(params[:target_of].to_sym)
    @model        =  Kernel.const_get(@attached_to.to_s.camelcase) if @attached_to
  end

  def set_targets
    today         = Date.today
    from_date     = Date.today - Date.today.mday + 1
    to_date       = Date.today - Date.today.mday + 365
    to_date       = Date.new(to_date.year, to_date.month, 1)
    @targets      = Target.all(:start_date.gte => from_date, :start_date.lte => to_date, :attached_to => @attached_to, :target_type => @target_type, :target_of => @target_of).group_by{|t|
      t.attached_id
    }.map{|staff_id, targets| [staff_id, targets.group_by{|target| target.start_date}]}.to_hash
  end
end # Targets
