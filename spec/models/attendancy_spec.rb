require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Attendancy do

  before(:each) do
  @attendancy=Attendancy.new(:date=>"2009-02-02",:status=>:absent)
  @manager = StaffMember.new(:name => "Mrs. M.A. Nerger")
  @center = Center.new(:name => "Munnar hill center")
  @branch = Branch.new(:name => "Kerela branch")
  @branch.manager = @manager
  @branch.should be_valid

  @center = Center.new(:name => "Munnar hill center")
  @center.manager = @manager
  @center.branch  = @branch
  @center.should be_valid

  @client = Client.new(:name => 'Ms C.L. Ient', :reference => 'XW000-2009.01.05')
  @client.center  = @center
  @attendancy.client=@client
  @attendancy.should be_valid
	end
 
  it "should not be valid without belonging to a client" do
	@attendancy.client=nil
	@attendancy.should_not be_valid
	end
  it "should not be valid without proper date" do
	@attendancy.date=nil
	@attendancy.should_not be_valid
	end
  it "should not be valid when attendancy date is in future" do
	@attendancy.date=Date.today + 1
	@attendancy.should_not be_valid
	end
  it "should not be valid without proper status" do
	@attendancy.status="ready"
 	@attendancy.should_not be_valid
	end


end
