require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Center do

  before(:all) do
    StaffMember.all.destroy!
    @manager = StaffMember.new(:name => "Mrs. M.A. Nerger")
    @manager.save
    @manager.should be_valid

    @user = User.new(:login => 'Joey', :password => 'password', :password_confirmation => 'password', :role => :admin, :active => true)
    @user.should be_valid
    @user.save

    @branch = Branch.new(:name => "Kerela branch")
    @branch.manager = @manager
    @branch.code = "bra"
    @branch.save
    @branch.should be_valid
  end

  before(:each) do
    Center.all.destroy!
    @center = Center.new(:name => "Munnar hill center")
    @center.manager = @manager
    @center.branch = @branch
    @center.code = "center"
    @center.save
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
    @user = User.create(:login => "branchmanager", :password => "branchmanager", :password_confirmation => "branchmanager", :role => :mis_manager)
    @client = Client.new(:name => name, :reference => ref, :date_joined => Date.today, :client_type => ClientType.create(:type => "standard"))
    @client.center     = @center
    @client.created_by = @user
    @client.save
    @client.errors.each {|e| p e}
    @client.should be_valid
    @client.save
    
    @center.clients << @client
    @center.should be_valid
    @center.clients.first.name.should eql(name)
    @center.clients.first.reference.should eql(ref)

    client2 = Client.new(:name => 'Mr. T.A. Kesmoney', :reference => 'AN000THER_REF', :date_joined => Date.today,
                         :client_type => ClientType.first, :created_by => @user)
    client2.center  = @center
    client2.created_by = @user
    client2.save
    client2.should be_valid

    @center.clients << client2
    @center.should be_valid
    @center.clients.size.should eql(2)
  end

end
