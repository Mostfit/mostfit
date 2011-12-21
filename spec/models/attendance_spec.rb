require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Attendance do
  before(:each) do
    Attendance.all.destroy!

    @attendancy = Factory(:attendance, :date => "2009-02-02", :status => :absent)
    @attendancy.should be_valid
  end
  
  it "should not be valid without belonging to a client" do
    @attendancy.client=nil
    @attendancy.should_not be_valid
  end
  it "should not be valid without proper date" do
    @attendancy.date=nil
    @attendancy.should_not be_valid
  end
  it "should not be valid when attendancy date is in future" do
    @attendancy.date=Date.today + 1
    @attendancy.should_not be_valid
  end
  it "should not be valid without proper status" do
    @attendancy.status="ready"
    @attendancy.should_not be_valid
  end
end
