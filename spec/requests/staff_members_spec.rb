require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a staff_member exists" do
  if StaffMember.all == []
    puts "loading StaffMember fixtures"
    load_fixtures :staff_members 
  end
end

given "an admin user" do
  load_fixtures :users if User.all == []
  response = request url(:perform_login), :method => "PUT", :params => { :login => 'admin', :password => 'password' }
  response.should redirect
end


describe "resource(:staff_members)", :given => "an admin user" do
  describe "GET" do

    before(:each) do
      @response = request(resource(:staff_members))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of staff_members" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a staff_member exists" do
    before(:each) do
      @response = request(resource(:staff_members))
    end
    
    it "has a list of staff_members" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST", :given => "an admin user" do
    before(:each) do
      StaffMember.all.destroy!
      @response = request(resource(:staff_members), :method => "POST", 
        :params => { :staff_member => { :name => "Test Staff Member" }})
    end
    
    it "redirects to resource(:staff_members)" do
      @response.should redirect_to(resource(:staff_members), :message => {:notice => "StaffMember was successfully created"})
    end
    
  end
end

describe "resource(@staff_member)" do 
  describe "a successful DELETE", :given => "an admin user" do
    before(:all) do
      load_fixtures :staff_members if StaffMember.all.blank?
    end

     before(:each) do
       @response = request(resource(StaffMember.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:staff_members))
     end

   end
end

describe "resource(:staff_members, :new)", :given => "an admin user"  do
  before(:each) do
    @response = request(resource(:staff_members, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@staff_member, :edit)", :given => "an admin user" do
  before(:all) do
    load_fixtures :staff_members if StaffMember.all.blank?
  end
  before(:each) do
    @response = request(resource(StaffMember.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@staff_member)", :given => "an admin user" do
  

  describe "GET" do
    before(:all) do
      load_fixtures :staff_members if StaffMember.all.blank?
    end
    before(:each) do
      @response = request(resource(StaffMember.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT", :given => "an admin user" do
    before(:each) do
      @staff_member = StaffMember.first
      @response = request(resource(:staff_members), :method => "PUT", 
        :params => { :staff_member => {:name => "abcde", :active => true} })
    end
  
    it "redirect to the article show action" do
      @response.should redirect_to(resource(@staff_member))
    end
  end
  
end

