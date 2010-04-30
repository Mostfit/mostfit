require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')

describe Clients, "Check clients details" do
  before do
    load_fixtures :users, :staff_members, :regions, :areas, :branches, :centers, :client_types, :clients
    @u_admin = User.new(:login => 'admin', :password => 'password', :password_confirmation => 'password', :role => :admin)
    @u_admin.save
  end

  it "create a new client" do
    response = request url(:perform_login), :method => "PUT", :params => {:login => 'admin', :password => 'password'}
    response.should redirect

    @center       = Center.first
    @branch       = @center.branch
    request(resource(@branch,@center,:clients, :new)).should be_successful
    @client_group = ClientGroup.first
    @client_type  = ClientType.first
    params = {}
    params[:client] =
      {
      :center_id => @center.id, :client_group_id => @client_group.id, :name => "Karina", :client_type_id => @client_type.id,
      :reference => "IDO3452546",:date_of_birth => {"month"=>"5", "day"=>"23", "year"=>"1970"}, :date_joined => {"month"=>"3", "day"=>"14", "year"=>"2009"},
      :grt_pass_date => { "month"=>"4", "day"=>"14", "year"=>"2009"}, :spouse_name => "Ashok"
    }
    response = request resource(@branch, @center, :clients), :method => "POST", :params => params
    response.should redirect
    Client.first(:reference => "IDO3452546").should_not nil
  end

  it "edit a new client" do
    response = request url(:perform_login), :method => "PUT", :params => {:login => 'admin', :password => 'password'}
    response.should redirect
    @client = Client.first
    request(resource(@client.center.branch)).should be_successful
    params = {}
    hash = @client.attributes
    hash.delete(:created_at)
    hash[:name]           = @client.name+"_modified"
    params[:client]       = hash
    params[:id]           = @client.id
    response = request resource(@client), :method => "POST", :params => params
    new_name = Client.get(@client.id).name
    new_name.should_not equal(@client.name)
  end

end
