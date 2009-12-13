require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a staff_member exists" do
  StaffMember.all.destroy!
  request(resource(:staff_members), :method => "POST", 
    :params => { :staff_member => { :name => "Gevine" }})
end

given "an authenticated user" do
  # load_fixtures :users, :staff_members, :branches, :centers, :clients #, :loans  #, :payments
  User.all.destroy!
  @u_data_entry = User.new(:login => 'data', :password => 'entry', :password_confirmation => 'entry', :role => :data_entry)
  @u_data_entry.save
  @u_data_entry.errors.each {|e| puts e}
  puts "ERROR data" unless @u_data_entry.errors.blank?
  @u_admin = User.new(:login => 'admin', :password => 'password', :password_confirmation => 'password', :role => :admin)
  @u_admin.save
  @u_admin.errors.each {|e| puts e}
  puts "ERROR admin" unless @u_admin.errors.blank?
  @u_mis_manager = User.new(:login => 'mis', :password => 'manager', :password_confirmation => 'manager', :role => :mis_manager)
  @u_mis_manager.save
  @u_mis_manager.errors.each {|e| puts e} 
  puts "ERROR mis" if @u_mis_manager.errors unless @u_mis_manager.errors.blank?
  response = request url(:perform_login), :method => "PUT", :params => { :login => 'admin', :password => 'password' }
  response.should redirect
end


describe "resource(:staff_members)", :given => "an authenticated user" do

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
        :params => { :staff_member => { :name => "Test Staff Member" }})
    end
    
    it "redirects to resource(:staff_members)" do
      @response.should redirect_to(resource(:staff_members), :message => {:notice => "StaffMember was successfully created"})
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

describe "resource(:staff_members, :new)", :given => "an authenticated user"  do
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

