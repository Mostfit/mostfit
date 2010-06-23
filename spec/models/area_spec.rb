require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Area do

  before(:all) do
    @manager = StaffMember.create(:name => "Region manager")
    @region  = Region.create(:name => "test region2", :manager => @manager)
    @region.should be_valid
    @area = Area.create(:name => "test area", :region => @region, :manager => @manager)
    @area.should be_valid
  end

  it "should have a name" do
    @area.name = nil
    @area.should_not be_valid
  end

  it "should have some branches" do
    @manager = StaffMember.new(:name => "Mrs. M.A. Nerger")
    @manager.save
    @manager.should be_valid
    @area.name =  "Foo"

    Branch.all.destroy!
    @branch = Branch.new(:name => "Kerela branch")
    @branch.manager = @manager
    @branch.code = "branch"
    @branch.area = @area
    @branch.save
    @branch.errors.each {|e| p e}
    @branch.should be_valid

    @branch.should be_valid
    @area.branches.should == [@branch]
  end
end
