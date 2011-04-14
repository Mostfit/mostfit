require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Region do
  before(:all) do
    load_fixtures :staff_members
  end
  
  it "should have a manager" do
    region = Region.new(:name => "foo")
    region.manager = nil
    region.should_not be_valid
    region.manager = StaffMember.first
    region.should be_valid
    region.save.should be_true
  end
  
  it "should have a unique name" do
    region = Region.new(:name => "foo")
    region.manager = StaffMember.first
    region.should_not be_valid
  end
  
  it "should have a name" do
    region = Region.new(:name => "f")
    region.manager = nil
    region.should_not be_valid
    region.manager = StaffMember.first
    region.should be_valid
    region.save.should be_true
  end
  

end
