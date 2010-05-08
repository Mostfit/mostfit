require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')


describe Regions, "Check region" do
  before do
    load_fixtures :users, :staff_members, :regions, :areas, :branches
    @u_admin = User.new(:login => 'admin', :password => 'password', :password_confirmation => 'password', :role => :admin)
    @u_admin.save
  end

  it "create a new area" do
    response = request url(:perform_login), :method => "PUT", :params => { :login => 'admin', :password => 'password'}
    response.should redirect
    request("/regions").should be_successful
    
    @staff_member = StaffMember.first
    
    params= {}
    
    params[:region]=
      {
      :name => "TestRegion", :manager_id => @staff_member.id, :address => " Adrash nagar", :contact_number => "9867453423", :landmark => "near Central jail",:creation_date => { "month" => "4", "day" => "3", "year" => "2009"}
    } 

    response = request url(:regions), :method => "POST", :params => params
    response.should redirect
    
    Region.name.should_not nil
    
    end

  it "edit a region" do 
    response = request url(:perform_login), :method => "PUT", :params => { :login => 'admin', :password => 'password'}
    response.should redirect
    @region = Region.first
    response = (request resource(@region)).should be_successful
    params = {}
    hash = @region.attributes
    hash[:name]= @region.name + "_modified"
    params[:id]= @region.id 

    response = request resource(@region), :method => "POST", :params => params
    
    new_name = Region.get(@region.id).name
    new_name.should_not equal(@region.name)
    
  end
    
    
end

    

