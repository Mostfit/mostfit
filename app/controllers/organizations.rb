class Organizations < Application
  provides :xml, :yaml, :js
  
  def index
    @organizations = Organization.all
    display @organizations
  end
  
  def show(id)
    @organization = Organization.get(id)
    raise NotFound unless @organization
    @domains = @organization.domains
    if params[:format] and API_SUPPORT_FORMAT.include?(params[:format])
      display [@organization, @domains]
    else
      display [@organization, @domains], 'domains/index', :layout => layout?
    end
  end
  
end
