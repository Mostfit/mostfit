class Centers < Application
  before :get_context, :exclude => ['redirect_to_show', 'groups']
  before :get_date,    :only    => ['show', 'weeksheet']
  provides :xml, :yaml, :js

  def index    
    redirect resource(@branch) if @branch
    hash = {:order => [:meeting_day]}
    hash[:manager] = session.user.staff_member if session.user.role == :staff_member
    hash[:branch] = @branch if @branch
    @centers = Center.all(hash).paginate(:per_page => 15, :page => params[:page] || 1)
    display @centers
  end

  def show(id)
    @center = Center.get(id)
    raise NotFound unless @center
    @branch  =  @center.branch if not @branch
    @clients = get_grouped_clients
    display [@center, @clients, @date], 'clients/index'
  end

  def today(id)
    @center = Center.get(id)
    raise NotFound unless @center
    @clients = @center.clients
    @loans = @clients.loans
    display [@center, @clients, @loans], 'clients/today'
  end

  def new
    only_provides :html
    @center = Center.new
    display @center
  end

  def create(center)
    @center = Center.new(center)
    if @branch
      @center.branch = @branch  # set direct context
    end
    if @center.save
      redirect(params[:return]||resource(@center), :message => {:notice => "Center '#{@center.name}' successfully created"})
    else
#       message[:error] = "Center failed to be created"
      render :new  # error messages will be shown
    end
  end

  def edit(id)
    only_provides :html
    @center = Center.get(id)
    raise NotFound unless @center
    display @center
  end

  def update(id, center)
    @center = Center.get(id)
    raise NotFound unless @center
    if @center.update_attributes(center)
      redirect(params[:return]||resource(@center), :message => {:notice => "Center '#{@center.name}' has been successfully edited"})
    else
      display @center, :edit  # error messages will be shown
    end
  end

  def delete(id)
    edit(id)  # so far these are the same
  end

  def destroy(id)
    @center = Center.get(id)
    raise NotFound unless @center
    if @center.destroy
      redirect resource(@branch, :centers), :message => {:notice => "Center '#{@center.name}' has been deleted"}
    else
      raise InternalServerError
    end
  end

  # this redirects to the proper url, used from the router
  def redirect_to_show(id)
    raise NotFound unless @center = Center.get(id)
    redirect resource(@center.branch, @center)
  end

  def groups
    only_provides :json
    if params[:group_id]
      group  = ClientGroup.get(params[:group_id])
      center = Center.get(params[:id])
      branch = center.branch
      render "{code: '#{branch.code.strip if branch and branch.code}#{center.code.strip if center and center.code}#{group.code.strip if group and group.code}'}"
    else
      @groups = Center.get(params[:id]).client_groups
      display @groups
    end
  end

  def weeksheet
    @clients_grouped = get_grouped_clients
    @clients = @center.clients
    partial "centers/weeksheet"
  end

  private
  include DateParser  # for the parse_date method used somewhere here..

  # this works from proper urls
  def get_context
    @branch       = Branch.get(params[:branch_id])
    @staff_member = StaffMember.get(params[:staff_member_id])
    @center       = Center.get(params[:center_id]) if params[:center_id]
    # raise NotFound unless @branch
  end

  def get_date
    if params[:date]
      if params[:date].is_a? String
        @date = Date.parse(params[:date])
      elsif params[:date].is_a? Mash
        @date = parse_date(params[:date])
      end
    else
      @date = Date.today
    end
  end
  
  def get_grouped_clients
    clients = {}
    @center.clients.each{|c|
      group_name = c.client_group ? c.client_group.name : "No group"
      clients[group_name]||=[]
      clients[group_name] << c
    }
    clients.each{|k, v|
      clients[k]=v.sort_by{|c| c.name} if v
    }.sort.collect{|k, v| v}.flatten
  end

end # Centers
