require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Location do

  before(:all) do
    @branch = Factory(:branch)
  end

  it "should have parent" do
    location = Location.create(:parent_id => @branch.id, :parent_type => "branch", :latitude => 30, :longitude => 40)
    location.should be_valid
    location.parent.should == @branch
  end

  it "should have valid latitude and longitudes" do
    location = Location.new(:parent_id => @branch.id, :parent_type => "branch", :latitude => 1000, :longitude => 40)
    location.should_not be_valid    

    location = Location.new(:parent_id => @branch.id, :parent_type => "branch", :latitude => 181, :longitude => 40)
    location.should_not be_valid    

    location = Location.new(:parent_id => @branch.id, :parent_type => "branch", :latitude => 90, :longitude => 40)
    location.should be_valid    

    location = Location.new(:parent_id => @branch.id, :parent_type => "branch", :latitude => -90, :longitude => 40)
    location.should be_valid

    location = Location.new(:parent_id => @branch.id, :parent_type => "branch", :latitude => -100, :longitude => 40)
    location.should_not be_valid

    location = Location.new(:parent_id => @branch.id, :parent_type => "branch", :latitude => -90, :longitude => 200)
    location.should_not be_valid    

    location = Location.new(:parent_id => @branch.id, :parent_type => "branch", :latitude => -90, :longitude => -190)
    location.should_not be_valid

  end

end

