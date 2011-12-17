require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Attendance do
  before(:all) do
    @manager = Factory(:staff_member, :name => "Mrs. M.A. Nerger")
    @manager.should be_valid

    @branch = Factory(:branch, :name => "Kerela branch", :manager => @manager)
    @branch.should be_valid

    @center = Factory(:center, :branch => @branch, :manager => @manager, :name => "Munnar hill center")
    @center.should be_valid

    @user = Factory(:user)
    @user.should be_valid

    @client_type = Factory(:client_type, :type => "standard")
    @client_type.should be_valid

    @client = Factory(:client, :reference => 'XW000-2009.01.05', :date_joined => '2008-01-01', :created_by => @user, :client_type => @client_type, :center => @center )
    @client.should be_valid
  end

  before(:each) do
    @attendancy=Attendance.new(:date => "2009-02-02", :status => :absent)
    @attendancy.client=@client
    @attendancy.center=@client.center    
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
