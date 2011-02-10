require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "an area and admin user" do
  load_fixtures :users, :staff_members, :regions, :areas
  @region = Region.first
  response = request url(:perform_login), :method => "PUT", :params => { :login => 'admin', :password => 'password' }
  response.should redirect
end

describe "resource(:areas)", :given => "an area and admin user" do
  describe "GET" do
    before(:each) do
      @response = request(resource(:areas))
    end

    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of areas" do
      pending
      @response.should have_xpath("//ul")
    end
  end
  
  describe "GET" do
    before(:each) do
      @response = request(resource(@region, :areas))
    end
    
    it "has a list of areas" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Area.all.destroy!
      @response = request(resource(@region, :areas), :method => "POST", :params => { :area => { :name => "Area1", :manager_id => 1, :region_id => 1 }})
    end
    
    it "redirects to resource(:areas)" do
      @response.should redirect_to(resource(Area.first), :message => {:notice => "area was successfully created"})
    end
  end
end

describe "resource(@area)" do 
  describe "a successful DELETE", :given => "an area and admin user" do
    before(:each) do
      @response = request(resource(Area.first.region, Area.first), :method => "DELETE")
    end

    it "should redirect to the index action" do
      @response.should redirect_to(resource(:areas))
    end
  end
end

describe "resource(:areas, :new)", :given => "an area and admin user" do
  before(:each) do
    @response = request(resource(@region, :areas, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@area, :edit)", :given => "an area and admin user" do
  before(:all) do
    load_fixtures :staff_members, :regions, :areas
  end

  before(:each) do
    @response = request(resource(Area.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@area)", :given => "an area and admin user" do
  describe "GET" do
    before(:each) do
      @response = request(resource(Area.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @area = Area.first
      @response = request(resource(@area), :method => "PUT", :params => { :area => {:id => @area.id} })
    end
  
    it "redirect to the area show action" do
      @response.should redirect_to(resource(@area))
    end
  end
end

