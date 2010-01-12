require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a holiday exists" do
  Holiday.all.destroy!
  request(resource(:holidays), :method => "POST", 
    :params => { :holiday => { :id => nil }})
end

describe "resource(:holidays)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:holidays))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of holidays" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a holiday exists" do
    before(:each) do
      @response = request(resource(:holidays))
    end
    
    it "has a list of holidays" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Holiday.all.destroy!
      @response = request(resource(:holidays), :method => "POST", 
        :params => { :holiday => { :id => nil }})
    end
    
    it "redirects to resource(:holidays)" do
      @response.should redirect_to(resource(Holiday.first), :message => {:notice => "holiday was successfully created"})
    end
    
  end
end

describe "resource(@holiday)" do 
  describe "a successful DELETE", :given => "a holiday exists" do
     before(:each) do
       @response = request(resource(Holiday.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:holidays))
     end

   end
end

describe "resource(:holidays, :new)" do
  before(:each) do
    @response = request(resource(:holidays, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@holiday, :edit)", :given => "a holiday exists" do
  before(:each) do
    @response = request(resource(Holiday.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@holiday)", :given => "a holiday exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Holiday.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @holiday = Holiday.first
      @response = request(resource(@holiday), :method => "PUT", 
        :params => { :holiday => {:id => @holiday.id} })
    end
  
    it "redirect to the holiday show action" do
      @response.should redirect_to(resource(@holiday))
    end
  end
  
end

