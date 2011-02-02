require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Branch do

  before(:all) do
    StaffMember.all.destroy!
    @manager = StaffMember.new(:name => "Mrs. M.A. Nerger")
    @manager.save
    @manager.errors
    @manager.should be_valid
  end

  before(:each) do
    Branch.all.destroy!
    @branch = Branch.new(:name => "Kerela branch")
    @branch.manager = @manager
    @branch.code = "branch"
    @branch.save
    @branch.errors.each {|e| p e}
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
    name = 'Munnar hill center'
    @center = Center.new(:name => name)
    @center.branch  = @branch
    @center.manager = @manager
    @center.code = "Cen"
    @center.save
    @center.errors.each {|e| puts e}
    @center.should be_valid

    # @branch.centers << @center
    @branch.should be_valid
    @branch.centers.first.name.should eql(name)

    kochin = Center.new(:name => 'Kochin harbour center', :code => "koch")
    kochin.branch  = @branch
    kochin.manager = @manager
    kochin.should be_valid

    @branch.centers << kochin
    @branch.should be_valid
    @branch.centers.size.should eql(2)
  end

end
