require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Target do
  before(:all) do
    load_fixtures :staff_members, :branches
  end
  
  before(:each) do
    10.times{|i|
      Center.create(:name => "foo_#{i}", :code => "foo#{i}", :manager => StaffMember.first, :branch => Branch.first)
    }

    @target = Target.new(:target_value => 100, :present_value => 20, :target_of => :center_creation,
                         :target_type => :relative, :start_date => Date.new(2010, 01, 01), :deadline => Date.new(2012, 01, 01),
                         :attached_to => :staff_member, :attached_id => StaffMember.first.id)
    @target.should be_valid
  end

  it "should have a target value" do
    @target.target_value = nil
    @target.should_not be_valid    
  end

  it "should have attached to something" do
    @target.attached_id = nil
    @target.should_not be_valid
  end

  it "should have deadline as future date" do
    @target.deadline = Date.today - 1
    @target.should_not be_valid
    @target.deadline = Date.today + 1
    @target.should be_valid
  end
  
  it "should have a deadline" do
    @target.deadline = nil
    @target.should_not be_valid
  end

  it "should have a deadline" do
    @target.start_date = nil
    @target.should_not be_valid
  end

  it "should have deadline as future date" do
    @target.target_value = nil
    @target.should_not be_valid

    @target.target_value = 0
    @target.should_not be_valid
    
    @target.target_value = 9
    @target.should_not be_valid

    @target.target_value = 100
    @target.should be_valid
  end
end
