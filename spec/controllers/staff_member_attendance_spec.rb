require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')

describe StaffMemberAttendances, "Check staff member attendances" do

  before(:all) do
    StaffMember.all.destroy!
    @staff_member = StaffMember.new(:name => "Mr. Prakash Raj")
    @staff_member.creation_date = Date.today
    @staff_member.gender = :male
    @staff_member.active = true
    @staff_member.save
    @staff_member.errors.each {|e| p e}
    @staff_member.should be_valid

    @u_admin = User.new(:login => 'admin', :password => 'password', :password_confirmation => 'password', :role => :admin)
    @u_admin.save
  end

  it "records a new attendance for staff member" do
    response = request url(:perform_login), :method => "PUT", :params => {:login => 'admin', :password => 'password'}
    response.should redirect
    request("/staff_members").should be_successful
    @staff_member = StaffMember.first
    params = {}
    params[:staff_member_attendance] = {:date => Date.today, :status => :present, :staff_member_id => @staff_member.id}
    response = request resource(@staff_member), :method => "POST", :params => params
    response.should redirect
    @staff_member.staff_member_attendances(:date => Date.today).should_not nil
  end    
end
