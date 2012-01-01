require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe AssetRegister do

  before(:all) do
    @manager = Factory(:staff_member)
    @manager.should be_valid
    @branch = Factory(:branch, :name => "Haridwar", :manager => @manager)
    @branch.should be_valid
  end

  before(:each) do
    AssetRegister.all.destroy!
    @asset_register = Factory(:asset_register, :branch => @branch, :manager => @manager)
    @asset_register.should be_valid
  end

  it "should not be valid without the person issuing the asset" do
    @asset_register.manager = nil
    @asset_register.should_not be_valid
  end
  
  it "should belong to a particular branch" do
    @asset_register.branch = @branch
    @asset_register.should be_valid
  end

  it "should not be valid without asset type" do
    @asset_register.asset_type = nil
    @asset_register.should_not be_valid
  end

  it "should not be valid without issue_date" do
    @asset_register.issue_date = nil
    @asset_register.should_not be_valid
  end
end
