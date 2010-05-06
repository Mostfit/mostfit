require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')

describe Areas, "Check area" do
  before do
    load_fixtures :users, :staff_members, :regions, :areas, :branches
    @u_admin = User.new(:login => 'admin', :password => 'password', :password_confirmation => 'password', :role => :admin)
    @u_admin.save
  end

  it "create a new area" do
    response = request url(:perform_login), :method => "PUT", :params => {:login => 'admin', :password => 'password'}
    response.should redirect
    request("/areas").should be_successful
    @staff_member = StaffMember.first
    @region       = Region.first
    params = {}
    params[:area] =
      {
      :name => "TestArea",:region_id => @region.id,:manager_id => @staff_member.id,:address => "Near malad station", :contact_number => "9078345621", :landmark => "The city mall"
    }
    response = request url(:areas), :method => "POST", :params => params
    response.should redirect
    Area.first(:name => "TestArea").should_not nil
  end

  it "edit a area" do
    response = request url(:perform_login), :method => "PUT", :params => {:login => 'admin', :password => 'password'}
    response.should redirect
    @area = Area.first
    response = (request resource(@area)).should be_successful

    params= {}
    hash = @area.attributes
    hash[:name] = @area.name + "_changed"
    params[:area] = hash
    params[:id] = @area.id
    
    response = request resource(@area), :method => "POST", :params => params
    
    new_name = Area.get(@area.id).name
    new_name.should_not equal(@area.name)
   
  end

end

 
