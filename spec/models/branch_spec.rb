require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Branch do

  before(:all) do
    Center.all.destroy!
    StaffMember.all.destroy!
    @manager = Factory( :staff_member )
    @manager.should be_valid
  end

  before(:each) do
    Branch.all.destroy!
    @branch = Factory(:branch)
  end

  it "should be valid with default attributes" do
    @branch.should be_valid
  end
 
  it "should not be valid without a manager" do
    @branch.manager = nil
    @branch.should_not be_valid
  end
 
  it "should not be valid without a name" do
    @branch.name = nil
    @branch.should_not be_valid
  end
 
  it "should not be valid with a name shorter than 3 characters" do
    @branch.name = "ok"
    @branch.should_not be_valid
  end
 
  it "should be able to 'have' centers" do
    center = Factory(:center, :branch => @branch, :manager => @branch.manager)
    center.should be_valid

    @branch.should be_valid
    @branch.centers.count.should eql(1)
    @branch.centers.first.name.should eql(center.name)

    second_center = Factory(:center, :branch => @branch, :manager => @branch.manager)
    second_center.should be_valid

    @branch.should be_valid
    @branch.centers.count.should eql(2)
    @branch.centers.last.name.should eql(second_center.name)
  end

end
