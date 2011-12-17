require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Center do

  before(:all) do
    StaffMember.all.destroy!
    User.all.destroy!
    Branch.all.destroy!

    @manager = Factory(:staff_member)
    @manager.should be_valid

    @user = Factory(:user)
    @user.should be_valid

    @branch = Factory(:branch, :manager => @manager)
    @branch.should be_valid
  end

  before(:each) do
    Center.all.destroy!
    @center = Center.new(:name => "Munnar hill center")
    @center.manager = @manager
    @center.branch = @branch
    @center.creation_date = Date.new(2010, 1, 1)
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

  # The following specs are currently failing because the method that sets up center_meeting_days
  # is borked. This is documented in the Center model itself.
  it "should have meeting_days" do
    @center.center_meeting_days.length.should eql(1)
    @center.should be_valid
  end

  it "should have meeting date change should create a new center_meeting_day entry" do
    @center.meeting_day = :tuesday
    @center.save
    @center.center_meeting_days.length.should eql(2)
    @center.should be_valid
  end
 
  it "meeting date change should happen on the date specified" do
    @center.meeting_day_change_date = Date.new(2010, 10, 12)
    @center.meeting_day = :tuesday
    @center.save
    @center =  Center.get(@center.id)
    @center.meeting_day_for(Date.new(2010, 10, 12)).should eql(:tuesday)
    @center.meeting_day_for(Date.new(2010, 10, 11)).should eql(:monday)
    @center.meeting_day_for(Date.new(2010, 10, 13)).should eql(:tuesday)
  end

  it "meeting date change should happen on the date specified" do
    @center.meeting_day_change_date = Date.new(2010, 10, 12)
    @center.meeting_day = :tuesday
    @center.save
    @center =  Center.get(@center.id)

    @center.next_meeting_date_from(Date.new(2010, 10, 12)).weekday.should eql(:tuesday)
    @center.previous_meeting_date_from(Date.new(2010, 10, 11)).weekday.should eql(:monday)

    @center.next_meeting_date_from(Date.new(2010, 10, 13)).weekday.should eql(:tuesday)
    @center.previous_meeting_date_from(Date.new(2010, 10, 13)).weekday.should eql(:monday)

    @center.next_meeting_date_from(Date.new(2010, 10, 11)).weekday.should eql(:tuesday)
    @center.previous_meeting_date_from(Date.new(2010, 10, 11)).weekday.should eql(:monday)
  end

  it "next and previous meeting dates should be correct" do
    center =  Center.create(:branch => @branch, :name => "center 75", :code => "c75", :creation_date => Date.new(2010, 03, 17),
                            :meeting_day => :wednesday, :manager => @manager)
    center.should be_valid

    center.next_meeting_date_from(Date.new(2010, 6, 30)).should   == Date.new(2010, 7, 7)
    center.next_meeting_date_from(Date.new(2010, 7, 1)).should    == Date.new(2010,  7, 7)
    center.next_meeting_date_from(Date.new(2010, 7, 3)).should    == Date.new(2010,  7, 7)
    center.next_meeting_date_from(Date.new(2010, 7, 5)).should    == Date.new(2010,  7, 7)
    center.next_meeting_date_from(Date.new(2010, 7, 6)).should    == Date.new(2010,  7, 7)

    center.meeting_day_change_date = Date.new(2010, 7, 8)
    center.meeting_day = :tuesday
    center.save
    center = Center.get(center.id)

    center.previous_meeting_date_from(Date.new(2010, 7, 7)).should == Date.new(2010, 6, 30)
    center.previous_meeting_date_from(Date.new(2010, 7, 12)).should == Date.new(2010, 7, 07)
    center.previous_meeting_date_from(Date.new(2010, 7, 6)).should == Date.new(2010, 6, 30)
    center.previous_meeting_date_from(Date.new(2010, 7, 1)).should == Date.new(2010, 6, 30)

    center.next_meeting_date_from(Date.new(2010, 7, 7)).should     == Date.new(2010, 7, 13)
    center.next_meeting_date_from(Date.new(2010, 7, 10)).should    == Date.new(2010, 7, 13)
    center.next_meeting_date_from(Date.new(2010, 7, 12)).should    == Date.new(2010, 7, 13)

    center.next_meeting_date_from(Date.new(2010, 7, 10)).should    == Date.new(2010, 7, 13)
    center.next_meeting_date_from(Date.new(2010, 7, 11)).should    == Date.new(2010, 7, 13)
    center.next_meeting_date_from(Date.new(2010, 7, 12)).should    == Date.new(2010, 7, 13)

    center.next_meeting_date_from(Date.new(2010, 7, 13)).should    == Date.new(2010, 7, 20)
    center.next_meeting_date_from(Date.new(2010, 7, 15)).should    == Date.new(2010, 7, 20)
    center.next_meeting_date_from(Date.new(2010, 7, 19)).should    == Date.new(2010, 7, 20)

    center.previous_meeting_date_from(Date.new(2010, 7, 20)).should == Date.new(2010, 7, 13)
    center.previous_meeting_date_from(Date.new(2010, 7, 19)).should == Date.new(2010, 7, 13)
    center.previous_meeting_date_from(Date.new(2010, 7, 14)).should == Date.new(2010, 7, 13)

    center.previous_meeting_date_from(Date.new(2010, 7, 13)).should == Date.new(2010, 7, 7)
    center.previous_meeting_date_from(Date.new(2010, 7, 12)).should == Date.new(2010, 7, 7)
    center.previous_meeting_date_from(Date.new(2010, 7, 8)).should == Date.new(2010, 7, 7)
        
    center.meeting_day_change_date = Date.new(2010, 10, 17)
    center.meeting_day = :friday
    center.save
    
    center = Center.get(center.id)
    
    center.next_meeting_date_from(Date.new(2010, 10, 12)).should == Date.new(2010, 10, 22)
    center.next_meeting_date_from(Date.new(2010, 10, 13)).should == Date.new(2010, 10, 22)
    center.next_meeting_date_from(Date.new(2010, 10, 15)).should == Date.new(2010, 10, 22)
    center.next_meeting_date_from(Date.new(2010, 10, 17)).should == Date.new(2010, 10, 22)
    center.next_meeting_date_from(Date.new(2010, 10, 20)).should == Date.new(2010, 10, 22)
    center.next_meeting_date_from(Date.new(2010, 10, 21)).should == Date.new(2010, 10, 22)

    center.previous_meeting_date_from(Date.new(2010, 10, 12)).should == Date.new(2010, 10, 5)
    center.previous_meeting_date_from(Date.new(2010, 10, 22)).should == Date.new(2010, 10, 12)
    center.next_meeting_date_from(Date.new(2010, 10, 22)).should == Date.new(2010, 10, 29)
    
    
    center =  Center.create(:branch => @branch, :name => "center 77", :code => "c77", :creation_date => Date.new(2010, 03, 15),
                            :meeting_day => :monday, :manager => @manager)
    center.should be_valid

    center.next_meeting_date_from(Date.new(2010, 3, 15)).should     == Date.new(2010,  3, 22)
    center.next_meeting_date_from(Date.new(2010, 3, 22)).should     == Date.new(2010,  3, 29)
    center.previous_meeting_date_from(Date.new(2010, 3, 29)).should == Date.new(2010,  3, 22)
    center.previous_meeting_date_from(Date.new(2010, 3, 22)).should  == Date.new(2010, 3, 15)

    center.meeting_day_change_date = Date.new(2010, 7, 14)
    center.meeting_day = :friday
    center.save
    center = Center.get(center.id)
    
    center.next_meeting_date_from(Date.new(2010, 7, 12)).should == Date.new(2010, 7, 23)
    center.next_meeting_date_from(Date.new(2010, 7, 15)).should == Date.new(2010, 7, 23)
    center.next_meeting_date_from(Date.new(2010, 7, 5)).should  == Date.new(2010, 7, 12)

    center.previous_meeting_date_from(Date.new(2010, 7, 23)).should == Date.new(2010, 7, 12)
    center.previous_meeting_date_from(Date.new(2010, 7, 20)).should == Date.new(2010, 7, 12)
    center.previous_meeting_date_from(Date.new(2010, 7, 13)).should == Date.new(2010, 7, 12)
    center.previous_meeting_date_from(Date.new(2010, 7, 14)).should == Date.new(2010, 7, 12)

    center.meeting_day_change_date = Date.new(2010, 8, 1)
    center.meeting_day = :none
    center.save

    center = Center.get(center.id)
    center.next_meeting_date_from(Date.new(2010, 7, 2)).should   == Date.new(2010,  7, 5)
    center.next_meeting_date_from(Date.new(2010, 7, 1)).should   == Date.new(2010, 7, 5)
    center.next_meeting_date_from(Date.new(2010, 7, 21)).should  == Date.new(2010, 7, 23)
    center.next_meeting_date_from(Date.new(2010, 7, 31)).should  == Date.new(2010, 8, 1)
    center.next_meeting_date_from(Date.new(2010, 8, 1)).should   == Date.new(2010, 8, 2)
    center.previous_meeting_date_from(Date.new(2010, 8, 2)).should    == Date.new(2010, 8, 1)
    center.previous_meeting_date_from(Date.new(2010, 8, 10)).should    == Date.new(2010, 8, 9)
  end

  it "should not be valid with a name shorter than 3 characters" do
    @center.name = "ok"
    @center.should_not be_valid
  end
 
  it "should be able to 'have' clients" do

    user = Factory(:user, :role => :mis_manager)
    user.should be_valid

    client = Factory(:client, :center => @center, :created_by => user)
    client.errors.each {|e| p e}
    client.should be_valid
    
    @center.clients.count.should eql(1)

    client2 = Factory(:client, :center => @center, :created_by => user)
    client2.errors.each {|e| p e}
    client2.should be_valid

    @center.clients.count.should eql(2)
  end

end
