class Locations < Application
  # provides :xml, :yaml, :js
  def index
    if params[:branch_id] and branch = Branch.get(params[:branch_id])
      @locations = (Location.all(:parent_type => "branch", :parent_id => params[:branch_id]) + Location.all(:parent_type => "center", :parent_id => branch.centers.map{|x| x.id})).flatten.uniq
    elsif params[:staff_member_id] and staff = StaffMember.get(params[:staff_member_id])
      @locations = (Location.all(:parent_type => "branch", :parent_id => staff.branches.map{|x| x.id}) + 
                    Location.all(:parent_type => "center", :parent_id => staff.centers.map{|x| x.id})).flatten.uniq
    elsif params[:meeting_today] and not params[:meeting_today].blank?
      @locations = Location.all(:parent_id => Center.meeting_today.map{|c| c.id}, :parent_type => "center")
    else
      @locations = Location.all
    end
    render :layout => layout?
  end

  def show(id)
    @location = Location.get(id)
    raise NotFound unless @location
    display @location
  end

  def new
    only_provides :html
    @location = Location.new
    display @location
  end

  def create(location)
    if (location[:parent_id] and location[:parent_type] and @location = Location.first(:parent_id => location[:parent_id], :parent_type => location[:parent_type]))
      @location.latitude  = location[:latitude]
      @location.longitude = location[:longitude]
    else
      @location = Location.new(location)
    end
    
    if @location.save
      if request.xhr?
        return("Location saved")
      else
        redirect(resource(@location), :message => {:notice => "Location was successfully created"})      
      end
    else
      if request.xhr?
        return("Location cannot be saved")
      else      
        message[:error] = "Location failed to be created"
        render :new, :layout => layout?
      end
    end
  end
end # Locations
