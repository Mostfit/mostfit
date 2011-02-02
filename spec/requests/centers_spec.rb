require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a center and admin user" do
  load_fixtures :users, :staff_members, :branches, :centers
  @branch = Branch.first
  response = request url(:perform_login), :method => "PUT", :params => { :login => 'admin', :password => 'password' }
  response.should redirect
end

describe "resource(:centers)", :given => "a center and admin user" do
  describe "GET" do
    before(:each) do
      @response = request(resource(:centers))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of centers" do
      pending
      @response.should have_xpath("//ul")
    end
  end
  
  describe "GET"  do
    before(:each) do
      @response = request(resource(@branch, :centers))
    end
    
    it "has a list of centers" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Center.all.destroy!
      @response = request(resource(@branch, :centers), :method => "POST", :params => { :center => { :name => "abc", :code => "ab", :meeting_day => :thursday, :meeting_time_hours => 8, :meeting_time_minutes => 0, :branch_id => 1, :manager_staff_id => 1}})
    end
    
    it "redirects to resource(:centers)" do
      @response.should redirect_to(resource(Center.first), :message => {:notice => "center was successfully created"})
    end
  end
end

describe "resource(@center)" do 
  describe "a successful DELETE", :given => "a center and admin user" do
    before(:each) do
      @response = request(resource(Center.first.branch, Center.first), :method => "DELETE")
    end

    it "should redirect to the index action" do
      @response.should redirect_to(resource(@branch, :centers))
    end
  end
end

describe "resource(:centers, :new)", :given => "a center and admin user" do
  before(:each) do
    @response = request(resource(@branch, :centers, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@center, :edit)", :given => "a center and admin user" do
 
  before(:all) do
    load_fixtures :staff_members, :branches, :centers
  end
  before(:each) do
    @response = request(resource(Center.first, :edit))
  end
  
  it "responds successfully" do
    pending
    @response.should be_successful
  end
end

describe "resource(:centers)", :given => "a center and admin user" do
  describe "GET" do
    before(:each) do
      @response = request(resource(Center.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @center = Center.first
      @response = request(resource(:centers), :method => "PUT", :params => { :center => {:id => @center.id} })
    end
  
    it "redirect to the article show action" do
      @response.should redirect_to(resource(:centers))
    end
  end
end
