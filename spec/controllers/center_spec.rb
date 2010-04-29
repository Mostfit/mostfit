require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')

describe Centers, "Check centers controller" do 
  before do
    load_fixtures :users, :staff_members, :regions, :areas, :branches, :centers 
    @u_admin = User.new(:login => 'admin', :password => 'password', :password_confirmation => 'password', :role => :admin)
    @u_admin.save
  end

  it "create a new center" do
    response = request url(:perform_login), :method => "PUT", :params => {:login => 'admin', :password => 'password'}
    response.should redirect
    request("/centers").should be_successful
    @staff_member = StaffMember.first
    @branch       = Branch.first
    params = {}
    params[:center] =
      {
      :branch_id => @branch.id, :name => "Test Center", :code => "C1", :creation_date => {"month"=>"4", "day"=>"29", "year"=>"2010"},
      :manager_staff_id => @staff_member.id
    }
    response = request url(:centers), :method => "POST", :params => params
    response.should redirect
    Center.first(:code => "C1").should_not nil
  end

  it "edit a new center" do
    response = request url(:perform_login), :method => "PUT", :params => {:login => 'admin', :password => 'password'}
    response.should redirect
    @center =  Center.first
    request(resource(@center)).should be_successful
    params = {}
    hash = @center.attributes
    hash.delete(:created_at)
    hash[:creation_date] = { :month => hash[:creation_date].month, :day => hash[:creation_date].day, :year => hash[:creation_date].year}
    hash[:name]          = @center.name+"_changed"
    params[:center]      =  hash
    response = request resource(@center), :method => "POST", :params => params
    response.should redirect
    new_name = Center.get(@center.id).name
    new_name.should_not equal(@center.name)
  end 

end
