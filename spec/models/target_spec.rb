require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Target do
  before(:all) do
    load_fixtures :staff_members
  end

  it "should have a target value" do
    @target = Target.new(:target_value => 100, :start_value => 10, :present_value => 20, :target_of => :center_creation,
                         :target_type => :absolute, :start_date => Date.new(2010, 01, 01), :deadline => Date.new(2012, 01, 01),
                         :attached_to => :staff_member, :attached_id => StaffMember.first.id)
    @target.should be_valid
    @target.target_value = nil
    @target.should_not be_valid    
  end


end
