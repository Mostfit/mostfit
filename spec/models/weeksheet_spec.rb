require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Weeksheet do

  before(:each) do
    @center = Center.get(11)
    @weeksheets = Weeksheet.get_center_sheet(@center, Date.today)
  end

  it "should be get center weeksheet" do
    @weeksheets.first.should_not == nil
  end

  it "should be equal to given date" do
  end

  it "total due should be equal principal+intrest+fee" do
  end

  it "Installment number should be befor given date" do
  end

  it "should be equal to given center_id" do
  end

  it "should get staff_member weeksheet" do
  end

  it "should not get center weeksheet if center not paying on given date" do
  end

  it "should not get staff_member weeksheet if not any center paying on given date" do
  end

end
