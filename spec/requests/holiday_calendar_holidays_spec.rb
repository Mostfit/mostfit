require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a holiday_calendar_holiday exists" do
  HolidayCalendarHoliday.all.destroy!
  request(resource(:holiday_calendar_holidays), :method => "POST", 
    :params => { :holiday_calendar_holiday => { :id => nil }})
end

describe "resource(:holiday_calendar_holidays)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:holiday_calendar_holidays))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of holiday_calendar_holidays" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a holiday_calendar_holiday exists" do
    before(:each) do
      @response = request(resource(:holiday_calendar_holidays))
    end
    
    it "has a list of holiday_calendar_holidays" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      HolidayCalendarHoliday.all.destroy!
      @response = request(resource(:holiday_calendar_holidays), :method => "POST", 
        :params => { :holiday_calendar_holiday => { :id => nil }})
    end
    
    it "redirects to resource(:holiday_calendar_holidays)" do
      @response.should redirect_to(resource(HolidayCalendarHoliday.first), :message => {:notice => "holiday_calendar_holiday was successfully created"})
    end
    
  end
end

describe "resource(@holiday_calendar_holiday)" do 
  describe "a successful DELETE", :given => "a holiday_calendar_holiday exists" do
     before(:each) do
       @response = request(resource(HolidayCalendarHoliday.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:holiday_calendar_holidays))
     end

   end
end

describe "resource(:holiday_calendar_holidays, :new)" do
  before(:each) do
    @response = request(resource(:holiday_calendar_holidays, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@holiday_calendar_holiday, :edit)", :given => "a holiday_calendar_holiday exists" do
  before(:each) do
    @response = request(resource(HolidayCalendarHoliday.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@holiday_calendar_holiday)", :given => "a holiday_calendar_holiday exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(HolidayCalendarHoliday.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @holiday_calendar_holiday = HolidayCalendarHoliday.first
      @response = request(resource(@holiday_calendar_holiday), :method => "PUT", 
        :params => { :holiday_calendar_holiday => {:id => @holiday_calendar_holiday.id} })
    end
  
    it "redirect to the holiday_calendar_holiday show action" do
      @response.should redirect_to(resource(@holiday_calendar_holiday))
    end
  end
  
end

