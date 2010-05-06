require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')

describe Holidays, "Check holidays" do
  before do
    load_fixtures :users, :staff_members, :regions, :areas, :branches,:centers,:client_groups,:client_types, :holidays
    @u_admin = User.new(:login => 'admin', :password => 'password', :password_confirmation => 'password', :role => :admin)
    @u_admin.save
  end

  it "create a new holiday" do
    response = request url(:perform_login), :method => "PUT", :params => {:login => 'admin', :password => 'password'}
    response.should redirect
    request("/holidays").should be_successful
    params = {}
    params[:holiday] =
      { :name => "sutti",:date => {"month" => "3", "day" => "14", "year" => "2010"}, :shift_meeting => "before" }
    response = request resource(:holidays), :method => "POST", :params => params
    response.should redirect
    Holiday.first(:name => "sutti").should_not nil
  end

  it "edit a holiday" do
    
    response = request url(:perform_login), :method => "PUT", :params => {:login => 'admin', :password => 'password' }
    response.should redirect
    @holiday = Holiday.first
    request(resource(@holiday)).should be_successful
    params = {}
    hash = @holiday.attributes
    hash[:name] = @holiday.name + "_modified"
    params[:holiday] = hash     
    response = request resource(@holiday),:method => "POST", :params =>params 
    
    new_name = Holiday.get(@holiday.id).name
    new_name.should_not equal(@holiday.name)

  end
    
end
