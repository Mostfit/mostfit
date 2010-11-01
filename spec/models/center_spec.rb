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
    @center.creation_date = Date.today - 100
    @center.meeting_day = :monday
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

  it "center should have meeting_days" do
    @center.center_meeting_days.length.should eql(1)
    @center.should be_valid
  end

  it "center should have meeting date change should create a new center_meeting_day entry" do
    @center.meeting_day = :tuesday
    @center.save
    @center.center_meeting_days.length.should eql(2)
    @center.should be_valid
  end
 
  it "meeting date change should happen on the date specified" do
    @center.meeting_day_change_date = Date.today - 50
    @center.meeting_day = :tuesday
    @center.save
    @center =  Center.get(@center.id)
    @center.meeting_day_for(Date.today-49).should eql(:tuesday)
    @center.meeting_day_for(Date.today-51).should eql(:monday)
  end

  it "meeting date change should happen on the date specified" do
    @center.meeting_day_change_date = Date.today - 50
    @center.meeting_day = :tuesday
    @center.save
    @center =  Center.get(@center.id)
    @center.next_meeting_date_from(Date.today-49).weekday.should eql(:tuesday)
    @center.previous_meeting_date_from(Date.today-49).weekday.should eql(:monday)

    @center.next_meeting_date_from(Date.today-51).weekday.should eql(:tuesday)
    @center.previous_meeting_date_from(Date.today-51).weekday.should eql(:monday)
  end

  it "next and previous meeting dates should be correct" do
    center =  Center.create(:branch => @branch, :name => "center 75", :code => "c75", :creation_date => Date.new(2010, 03, 17),
                            :meeting_day => :wednesday, :manager => @manager)
    center.should be_valid
    center.meeting_day_change_date = Date.new(2010, 7, 7)
    center.meeting_day = :tuesday    
    center.save
    center = Center.get(center.id)
    
    center.previous_meeting_date_from(Date.new(2010, 7, 7)).should == Date.new(2010, 6, 30)
    center.next_meeting_date_from(Date.new(2010, 7, 7)).should     == Date.new(2010, 7, 13)
    center.next_meeting_date_from(Date.new(2010, 7, 13)).should    == Date.new(2010, 7, 20)
    center.previous_meeting_date_from(Date.new(2010, 7, 20)).should == Date.new(2010, 7, 13)
    center.previous_meeting_date_from(Date.new(2010, 7, 13)).should == Date.new(2010, 7, 7)
        
    center.meeting_day_change_date = Date.new(2010, 10, 17)
    center.meeting_day = :friday
    center.save
    
    center = Center.get(center.id)
    
    center.next_meeting_date_from(Date.new(2010, 10, 12)).should == Date.new(2010, 10, 22)
    center.previous_meeting_date_from(Date.new(2010, 10, 12)).should == Date.new(2010, 10, 5)
    center.previous_meeting_date_from(Date.new(2010, 10, 22)).should == Date.new(2010, 10, 12)
    center.next_meeting_date_from(Date.new(2010, 10, 22)).should == Date.new(2010, 10, 29)
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
