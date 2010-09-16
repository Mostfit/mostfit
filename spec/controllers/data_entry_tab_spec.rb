require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')

#Controller spec for Branches.

describe Branches, "Check branches" do
  before do
    load_fixtures :users, :staff_members, :regions, :areas
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
    params[:branch] = {:name => "Test", :code => "T1", :contact_number => "9850783543", :creation_date => {"month" => "4", "day" => "29", "year" => "2010"}, :manager_staff_id => @staff_member.id,:area_id => @area.id}
    response = request url(:branches), :method => "POST", :params => params
    response.should redirect
    Branch.first(:code => "T1").should_not nil
  end

  it "edit a new branch" do
    response = request url(:perform_login), :method => "PUT", :params => {:login => 'admin', :password => 'password'}
    response.should redirect
    @branch = Branch.first
    request(resource(@branch)).should be_successful
    params = {}
    hash = @branch.attributes
    hash.delete(:created_at)
    hash[:creation_date] = { :month => hash[:creation_date].month, :day => hash[:creation_date].day, :year => hash[:creation_date].year}
    hash[:name]             = @branch.name+"_changed"
    params[:branch]         = hash
    response = request resource(@branch), :method => "POST", :params => params
    response.should redirect
    new_name = Branch.get(@branch.id).name
    new_name.should_not equal(@branch.name)
  end

  #Controller spec for Centers.

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
      params[:center] = {:branch_id => @branch.id, :name => "Test Center", :code => "C1", :creation_date => {"month" => "4", "day" => "29", "year" => "2010"}, :manager_staff_id => @stafff_member.id}
      response = request url(:centers), :method => "POST", :params => params
      response.should redirect
      Center.first(:code => "C1").should_not nil
    end

    it "edit a new center" do
      response = request url(:perform_login), :method => "PUT", :params => {:login => 'admin', :password => 'password'}
      response.should redirect
      @center = Center.first
      request(resource(@center)).should be_successful
      params = {}
      hash = @center.attributes
      hash.delete(:created_at)
      hash[:creation_date] = { :month => hash[:creation_date].month, :day => hash[:creation_date].day, :year => hash[:creation_date].year}
      hash[:name]        = @center.name+"_changed"
      params[:center]    = hash
      response = request resource(@center), :method => "POST", :params => params
      response.should redirect
      new_name = Center.get(@center.id).name
      new_name.should_not equal(@center.name)
    end
  end

  #Controller spec for Groups.

  describe ClientGroups, "Check groups" do
    before do
      load_fixtures :users, :staff_members, :regions, :areas, :branches, :centers, :client_groups
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
      params[:client_group] = {:center_id => @center.id, :name => "Test Group", :code => "TG", :number_of_members => 5}
      response = request resource(:client_groups), :method => "POST", :params => params
      response.should redirect
      ClientGroup.first(:code => "TG").should_not nil
    end

    it "edit a new group" do
      response = request url(:perform_login), :method => "PUT", :params => {:login => 'admin', :password => 'password'}
      response.should redirect
      @group = ClientGroup.first
      request(resource(@group)).should be_successful
      params = {}
      hash = @group.attributes
      hash.delete(:created_at)
      hash[:name]             = @group.name+"_changed"
      params[:client_group]   = hash
      params[:id]             = @group.id
      response = request resource(@group.center.branch, @group.center, @group), :method => "POST", :params => params
      new_name = ClientGroup.get(@group.id).name
      new_name.should_not equal(@group.name)
    end
  end

  #Controller spec for Clients.

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
      params[:client] = {
        :center_id => @center.id, :client_group_id => @client_group.id, :name => "Karina", 
        :client_type_id => @client_type.id, :reference => "IDO3452546", :date_of_birth => "1970-5-23", 
        :date_joined => {"month"=>"3", "day"=>"14","year"=>"2009"}, :grt_pass_date => {"month"=>"4", "day"=>"14", "year"=>"2009"}, 
        :spouse_name => "Ashok"
      }
      response = request resource(@branch, @center, :clients), :method => "POST", :params => params
      response.should redirect
      Clients.first(:reference => "IDO3452546").should_not nil
    end

    it "edit a new client" do
      response = request url(:perform_login), :method => "PUT", :params => {:login => 'admin', :password => 'password'}
      response.should redirect
      @client = Client.first
      request(resource(@client.center.branch)).should be_successful
      params = {}
      hash = @client.attributes
      hash.delete(:created_at)
      hash[:name]          = @client.name+"_modified"
      params[:client]      = hash
      params[:id]          = @client.id
      response = request resource(@client), :method => "POST", :params => params
      new_name = Client.get(@client.id).name
      new_name.should_not equal(@client.name)
    end
  end
end
