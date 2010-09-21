require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')

describe ClientTypes, "Check types" do
  before do
    load_fixtures :users, :staff_members, :regions, :areas, :branches,:centers,:client_groups,:client_types
  end

  it "create a new client type" do
    response = request url(:perform_login), :method => "PUT", :params => {:login => 'admin', :password => 'password'}
    response.should redirect
    request("/client_types").should be_successful
    params = {}
    params[:client_type] =
      { :type => "Wanted"}
    response = request resource(:client_types), :method => "POST", :params => params
    response.should redirect
    ClientType.first(:type => "wanted").should_not nil
  end

  it "edit a client type" do
    response = request url(:perform_login), :method => "PUT",:params  => {:login => 'admin', :password => 'password'}
    response.should redirect 
    @client_type= ClientType.first
    request(resource(@client_type)).should be_successful 
    params = {}
    hash = @client_type.attributes
    hash[:type] = @client_type.type+"_modified"
    params[:id] = @client_type.id 
    response = request resource(@client_type), :method => "POST", :params => params
    new_type = ClientType.get(@client_type.id).type
    new_type.should_not equal(@client_type.type) 
    end 
 
end
