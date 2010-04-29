require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')

describe Branches, "Check branches" do 
  before do
    load_fixtures :users, :staff_members, :regions, :areas, :branches
    @u_admin = User.new(:login => 'admin', :password => 'password', :password_confirmation => 'password', :role => :admin)
    @u_admin.save
  end

  it "create a new branch" do
    response = request url(:perform_login), :method => "PUT", :params => {:login => 'admin', :password => 'password'}
    response.should redirect
    request("/branches").should be_successful
    @staff_member = StaffMember.first
    @area         = Area.first
    params = {}
    params[:branch] =
      {
      :name => "Test", :code => "T1", :contact_number => "9850783543", :creation_date => {"month"=>"4", "day"=>"29", "year"=>"2010"},
      :manager_staff_id => @staff_member.id,:area_id => @area.id
    }
    response = request url(:branches), :method => "POST", :params => params
    response.should redirect
    Branch.first(:code => "T1").should_not nil
  end

  it "edit a new branch" do
    response = request url(:perform_login), :method => "PUT", :params => {:login => 'admin', :password => 'password'}
    response.should redirect
    @branch =  Branch.first
    request(resource(@branch)).should be_successful
    params = {}
    hash = @branch.attributes
    hash.delete(:created_at)
    hash[:creation_date] = { :month => hash[:creation_date].month, :day => hash[:creation_date].day, :year => hash[:creation_date].year}
    hash[:name]          = @branch.name+"_changed"
    params[:branch]      =  hash
    response = request resource(@branch), :method => "POST", :params => params
    response.should redirect
    new_name = Branch.get(@branch.id).name
    new_name.should_not equal(@branch.name)
  end

end




