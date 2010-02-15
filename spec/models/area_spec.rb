require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Area do

  before(:each) do
    @area = Area.new(:name => "test area")
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

    Branch.all.destroy!
    @branch = Branch.new(:name => "Kerela branch")
    @branch.manager = @manager
    @branch.code = "branch"
    @branch.save
    @branch.errors.each {|e| p e}
    @branch.should be_valid

    @branch.area = @area
    @area.branches.should == [@branch]
  end


end
