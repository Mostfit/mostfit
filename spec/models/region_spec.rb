require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Region do

  before(:all) do
    @manager = Factory(:staff_member)
  end

  before(:each) do
    @region = Factory(:region)
  end

  it "should have a manager" do
    @region.manager = nil
    @region.should_not be_valid
    @region.manager = @manager
    @region.should be_valid
  end
  
  it "should have a name" do
    @region.name = nil
    @region.should_not be_valid
  end

  it "should have a unique name" do
    new_region = Factory(:region, :name => @region.name)
    new_region.should_not be_valid
  end
  
end
