require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe StaffMember do
  before(:each) do
    StaffMember.all.destroy!
    @staff_member = Factory(:staff_member)
  end

  it "should not be valid without a name" do
    @staff_member.name = nil
    @staff_member.should_not be_valid
  end

  it "should not be valid without active boolean" do
    @staff_member.active = nil
    @staff_member.should_not be_valid
  end

  it "should have name length > 3" do
    @staff_member.name = "ab"
    @staff_member.should_not be_valid
  end

  it "should have a unique name" do
    @new_staff_member = Factory(:staff_member, :name => @staff_member.name)
    @new_staff_member.should_not be_valid
  end

  # Still fails because the upload relation is currently not available
  # unless the app runs in migration mode
  it "should not require an upload" do
    @staff_member.upload_id = nil
    @staff_member.should be_valid
  end
end
