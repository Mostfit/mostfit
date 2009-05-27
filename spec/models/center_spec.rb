require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Center do

  before(:each) do
    @manager = StaffMember.new(:name => "Mrs. M.A. Nerger")
    @manager.should be_valid

    @branch = Branch.new(:name => "Kerela branch")
    @branch.manager = @manager
    @branch.should be_valid

    @center = Center.new(:name => "Munnar hill center")
    @center.manager = @manager
    @center.branch = @branch
    @center.should be_valid
  end
 
  it "should not be valid without a manager" do
    @center.manager = nil
    @center.should_not be_valid
  end
 
  it "should not be valid without a name" do
    @center.name = nil
    @center.should_not be_valid
  end
 
  it "should not be valid with a name shorter than 3 characters" do
    @center.name = "ok"
    @center.should_not be_valid
  end
 
  it "should be able to 'have' clients" do
    name = 'Ms C.L. Ient'
    ref  = 'XW000-2009.01.05'
    @client = Client.new(:name => name, :reference => ref)
    @client.center  = @center
    @client.should be_valid

    @center.clients << @client
    @center.should be_valid
    @center.clients.first.name.should eql(name)
    @center.clients.first.reference.should eql(ref)

    client2 = Client.new(:name => 'Mr. T.A. Kesmoney', :reference => 'AN000THER_REF')
    client2.center  = @center
    client2.should be_valid

    @center.clients << client2
    @center.should be_valid
    @center.clients.size.should eql(2)
  end

end