require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a staff_member exists" do
  StaffMember.all.destroy!
  request(resource(:staff_members), :method => "POST", 
    :params => { :staff_member => { :id => nil }})
end

describe "resource(:staff_members)" do
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
  
  describe "a successful POST" do
    before(:each) do
      StaffMember.all.destroy!
      @response = request(resource(:staff_members), :method => "POST", 
        :params => { :staff_member => { :id => nil }})
    end
    
    it "redirects to resource(:staff_members)" do
      @response.should redirect_to(resource(StaffMember.first), :message => {:notice => "staff_member was successfully created"})
    end
    
  end
end

describe "resource(@staff_member)" do 
  describe "a successful DELETE", :given => "a staff_member exists" do
     before(:each) do
       @response = request(resource(StaffMember.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:staff_members))
     end

   end
end

describe "resource(:staff_members, :new)" do
  before(:each) do
    @response = request(resource(:staff_members, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@staff_member, :edit)", :given => "a staff_member exists" do
  before(:each) do
    @response = request(resource(StaffMember.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@staff_member)", :given => "a staff_member exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(StaffMember.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @staff_member = StaffMember.first
      @response = request(resource(@staff_member), :method => "PUT", 
        :params => { :staff_member => {:id => @staff_member.id} })
    end
  
    it "redirect to the article show action" do
      @response.should redirect_to(resource(@staff_member))
    end
  end
  
end

