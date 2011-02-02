require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a branch exists" do
  Branch.all.destroy!
  StaffMember.all.destroy!
  load_fixtures :users if User.all.blank?
  load_fixtures :staff_members if StaffMember.all.blank?
  load_fixtures :branches if Branch.all.blank?
end

given "an admin user" do
  load_fixtures :users if User.all.blank?
  response = request url(:perform_login), :method => "PUT", :params => { :login => 'admin', :password => 'password' }
  response.should redirect
end

given "a branch and admin user exist" do
  load_fixtures :users if User.all.blank?
  load_fixtures :staff_members if StaffMember.all.blank?
  load_fixtures :branches if Branch.all.blank?
  response = request url(:perform_login), :method => "PUT", :params => { :login => 'admin', :password => 'password' }
  response.should redirect
end

describe "resource(:branches)", :given => "an admin user" do
  describe "GET" do
    before(:each) do
      @response = request(resource(:branches))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of branches" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a branch exists" do
    before(:each) do
      @response = request(resource(:branches))
    end
    
    it "has a list of branches" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST", :given => "an admin user" do
    before(:each) do
      Branch.all.destroy!
      load_fixtures :staff_members if StaffMember.all.blank?
      @response = request(resource(:branches), :method => "POST", 
        :params => { :branch => { :name => "BR1", :code => "1234",
                            :manager_staff_id => StaffMember.first.id}})
    end
    
    it "redirects to resource(:branches)" do
      @response.should redirect_to(resource(:branches), :message => {:notice => "branch was successfully created"})
    end
    
  end
end

describe "resource(@branch)", :given => "an admin user" do 
  describe "a successful DELETE", :given => "a branch exists" do
     before(:each) do
       @response = request(resource(Branch.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:branches))
     end

   end
end

describe "resource(:branches, :new)", :given => "an admin user" do
  before(:each) do
    @response = request(resource(:branches, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@branch, :edit)", :given => "an admin user" do
  before(:all) do
    load_fixtures :staff_members, :branches if Branch.all.blank?
  end
  before(:each) do
    @response = request(resource(Branch.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@branch)", :given => "a branch and admin user exist" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Branch.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @branch = Branch.first
      @response = request(resource(@branch), :method => "PUT", 
        :params => { :branch => {:id => @branch.id} })
    end
  
    it "redirect to the article show action" do
      @response.should redirect_to(resource(:branches))
    end
  end
  
end

