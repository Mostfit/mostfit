require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Attendancy do
  before(:all) do
    @manager = StaffMember.new(:name => "Mrs. M.A. Nerger")
    @manager.save
    @manager.should be_valid

    @branch = Branch.new(:name => "Kerela branch")
    @branch.manager = @manager
    @branch.code = "bra"
    @branch.save
    @branch.should be_valid

    @center = Center.new(:name => "Munnar hill center")
    @center.manager = @manager
    @center.branch  = @branch
    @center.code = "cen"
    @center.save
    @center.should be_valid
    
    @client = Client.new(:name => 'Ms C.L. Ient', :reference => 'XW000-2009.01.05', :date_joined => '2008-01-01')
    @client.center  = @center
    @client.save
    @client.errors.each {|e| puts e}
    @client.should be_valid
  end

  before(:each) do
    @attendancy=Attendancy.new(:date=>"2009-02-02",:status=>:absent)
    @attendancy.client=@client
    @attendancy.valid?
    @attendancy.errors.each {|e| puts e}
    # @attendancy.should be_valid
  end
  
  it "should not be valid without belonging to a client" do
    @attendancy.client=nil
    # @attendancy.should_not be_valid
  end
  it "should not be valid without proper date" do
    @attendancy.date=nil
    # @attendancy.should_not be_valid
  end
  it "should not be valid when attendancy date is in future" do
    @attendancy.date=Date.today + 1
    # @attendancy.should_not be_valid
  end
  it "should not be valid without proper status" do
    @attendancy.status="ready"
    # @attendancy.should_not be_valid
  end
end
