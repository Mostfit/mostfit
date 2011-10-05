require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a holiday_calendar exists" do
  HolidayCalendar.all.destroy!
  request(resource(:holiday_calendars), :method => "POST", 
    :params => { :holiday_calendar => { :id => nil }})
end

describe "resource(:holiday_calendars)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:holiday_calendars))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of holiday_calendars" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a holiday_calendar exists" do
    before(:each) do
      @response = request(resource(:holiday_calendars))
    end
    
    it "has a list of holiday_calendars" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      HolidayCalendar.all.destroy!
      @response = request(resource(:holiday_calendars), :method => "POST", 
        :params => { :holiday_calendar => { :id => nil }})
    end
    
    it "redirects to resource(:holiday_calendars)" do
      @response.should redirect_to(resource(HolidayCalendar.first), :message => {:notice => "holiday_calendar was successfully created"})
    end
    
  end
end

describe "resource(@holiday_calendar)" do 
  describe "a successful DELETE", :given => "a holiday_calendar exists" do
     before(:each) do
       @response = request(resource(HolidayCalendar.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:holiday_calendars))
     end

   end
end

describe "resource(:holiday_calendars, :new)" do
  before(:each) do
    @response = request(resource(:holiday_calendars, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@holiday_calendar, :edit)", :given => "a holiday_calendar exists" do
  before(:each) do
    @response = request(resource(HolidayCalendar.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@holiday_calendar)", :given => "a holiday_calendar exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(HolidayCalendar.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @holiday_calendar = HolidayCalendar.first
      @response = request(resource(@holiday_calendar), :method => "PUT", 
        :params => { :holiday_calendar => {:id => @holiday_calendar.id} })
    end
  
    it "redirect to the holiday_calendar show action" do
      @response.should redirect_to(resource(@holiday_calendar))
    end
  end
  
end

