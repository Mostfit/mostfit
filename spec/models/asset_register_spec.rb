require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe AssetRegister do

  before(:all) do
    StaffMember.all.destroy!
    @manager = StaffMember.new(:name => "Mr. Ramesh Sinha")
    @manager.save
    @manager.errors
    @manager.should be_valid
  end

  before(:all) do
    Branch.all.destroy!
    @branch = Branch.new(:name => "Haridwar")
    @branch.manager = @manager
    @branch.code = "branch1"
    @branch.save
    @branch.errors.each {|e| p e}
    @branch.should be_valid
  end

  before(:each) do
    AssetRegister.all.destroy!
    @asset_register               = AssetRegister.new
    @asset_register.branch        = @branch
    @asset_register.manager       = @manager
    @asset_register.name          = "Rahul Dev"
    @asset_register.asset_type    = "Laptop Charger"
    @asset_register.issue_date    = '17-02-2011'
    @asset_register.returned_date = '27-02-2011'
    @asset_register.save
    @asset_register.errors {|e| p e}
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
