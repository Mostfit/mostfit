require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')

describe ClientGroups, "Check groups" do
  before do
    load_fixtures :users, :staff_members, :regions, :areas, :branches,:centers,:client_groups  
    @u_admin = User.new(:login => 'admin', :password => 'password', :password_confirmation => 'password', :role => :admin)
    @u_admin.save
  end

  it "create a new group" do
    response = request url(:perform_login), :method => "PUT", :params => {:login => 'admin', :password => 'password'}
    response.should redirect
    request("/client_groups/new").should be_successful
    
    @center   = Center.first
    @branch   = @center.branch
    params = {}
    params[:client_group] =
      {:center_id => @center.id, :name => "Test Group", :code => "TG", :number_of_members => 5 }
    response = request resource(:client_groups), :method => "POST", :params => params
    response.should redirect
    ClientGroup.first(:code => "TG").should_not nil
  end

  it "edit a new group" do
  response = request url(:perform_login), :method => "PUT", :params => {:login => 'admin', :password => 'password'}
    response.should redirect
    @group =  ClientGroup.first
    request(resource(@group)).should be_successful
    params = {}
    hash = @group.attributes
    hash.delete(:created_at)
    hash[:name]           = @group.name+"_changed"
    params[:client_group] =  hash
    params[:id]           = @group.id
    response = request resource(@group.center.branch, @group.center, @group), :method => "POST", :params => params
    new_name = ClientGroup.get(@group.id).name
    new_name.should_not equal(@group.name)
  end
end 

