require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a staff_member_attendance exists" do
  StaffMemberAttendance.all.destroy!
  request(resource(:staff_member_attendances), :method => "POST", 
    :params => { :staff_member_attendance => { :id => nil }})
end

describe "resource(:staff_member_attendances)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:staff_member_attendances))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of staff_member_attendances" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a staff_member_attendance exists" do
    before(:each) do
      @response = request(resource(:staff_member_attendances))
    end
    
    it "has a list of staff_member_attendances" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      StaffMemberAttendance.all.destroy!
      @response = request(resource(:staff_member_attendances), :method => "POST", 
        :params => { :staff_member_attendance => { :id => nil }})
    end
    
    it "redirects to resource(:staff_member_attendances)" do
      @response.should redirect_to(resource(StaffMemberAttendance.first), :message => {:notice => "staff_member_attendance was successfully created"})
    end
    
  end
end

describe "resource(@staff_member_attendance)" do 
  describe "a successful DELETE", :given => "a staff_member_attendance exists" do
     before(:each) do
       @response = request(resource(StaffMemberAttendance.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:staff_member_attendances))
     end

   end
end

describe "resource(:staff_member_attendances, :new)" do
  before(:each) do
    @response = request(resource(:staff_member_attendances, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@staff_member_attendance, :edit)", :given => "a staff_member_attendance exists" do
  before(:each) do
    @response = request(resource(StaffMemberAttendance.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@staff_member_attendance)", :given => "a staff_member_attendance exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(StaffMemberAttendance.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @staff_member_attendance = StaffMemberAttendance.first
      @response = request(resource(@staff_member_attendance), :method => "PUT", 
        :params => { :staff_member_attendance => {:id => @staff_member_attendance.id} })
    end
  
    it "redirect to the staff_member_attendance show action" do
      @response.should redirect_to(resource(@staff_member_attendance))
    end
  end
  
end

