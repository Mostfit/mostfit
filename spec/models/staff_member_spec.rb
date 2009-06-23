require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe StaffMember do

  before(:each) do
    @staff_member = StaffMember.new
  end

  it "should not be valid without a name" do
    @staff_member.should_not be_valid
  end

  it "should not  be valid without active boolean" do
    @staff_member.name = "Test Staff"
    @staff_member.active = nil
    @staff_member.should_not be_valid
  end

  it "should be unique" do
    @staff_member.name = "Test Staff"
    @new_staff_member = StaffMember.new
    @new_staff_member.name = "Test Staff"
    if @staff_member.save
      @new_staff_member.save
      @new_staff_member.should_not be_valid
    else
      p @staff_member.errors
    end
  end
    
  it "should have name length > 3" do
    @staff_member.name = "ab"
    @staff_member.should_not be_valid
  end
    
end
