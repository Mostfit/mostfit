require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe StaffMemberAttendance do

  before(:all) do
    StaffMember.all.destroy!
    @staff_member = StaffMember.new(:name => "Mr. Prakash Raj")
    @staff_member.creation_date = Date.today
    @staff_member.gender = :male
    @staff_member.active = true
    @staff_member.save
    @staff_member.errors.each {|e| p e}
    @staff_member.should be_valid
  end

  before(:each) do
    StaffMemberAttendance.all.destroy!
    @staff_member_attendance = StaffMemberAttendance.new
    @staff_member_attendance.staff_member_id = @staff_member.id
    @staff_member_attendance.date = Date.today
    @staff_member_attendance.status = :present
    @staff_member_attendance.save
    @staff_member_attendance.errors.each {|e| p e}
    @staff_member_attendance.should be_valid
  end

  it "should not be valid without a staff member" do
    @staff_member_attendance.staff_member = nil
    @staff_member_attendance.should_not be_valid
  end

  it "should belong to a particular staff member" do
    @staff_member_attendance.staff_member = @staff_member
    @staff_member_attendance.should be_valid
  end

  it "should not be valid without a date" do
    @staff_member_attendance.date = nil
    @staff_member_attendance.should_not be_valid
  end

  it "should not be valid without a status" do
    @staff_member_attendance.status = nil
    @staff_member_attendance.should_not be_valid
  end

  it "should have a unique attendance date with respect to a staff member" do
    @staff_member_attendance.staff_member = @staff_member
    @staff_member_attendance.date = Date.today
    @staff_member_attendance.should be_valid
  end

  it "should not be valid for future dates" do
    @staff_member_attendance.date = Date.today + 1
    @staff_member_attendance.should_not be_valid
  end

end
