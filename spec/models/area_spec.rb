require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Area do

  before(:all) do
    @manager = Factory(:staff_member)
    @manager.should be_valid

    @region = Factory(:region, :manager => @manager)
    @region.should be_valid
  end

  before(:each) do
    @area = Factory(:area, :region => @region, :manager => @manager)
    @area.should be_valid
  end

  it "should have a name" do
    @area.name = nil
    @area.should_not be_valid
  end

  it "should have some branches" do
    branch = Factory(:branch, :manager => @manager, :area => @area)
    branch.should be_valid

    @area.branches.should include(branch)
  end
end
