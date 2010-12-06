require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a location exists" do
  Location.all.destroy!
  request(resource(:locations), :method => "POST", 
    :params => { :location => { :id => nil }})
end

describe "resource(:locations)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:locations))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of locations" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a location exists" do
    before(:each) do
      @response = request(resource(:locations))
    end
    
    it "has a list of locations" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Location.all.destroy!
      @response = request(resource(:locations), :method => "POST", 
        :params => { :location => { :id => nil }})
    end
    
    it "redirects to resource(:locations)" do
      @response.should redirect_to(resource(Location.first), :message => {:notice => "location was successfully created"})
    end
    
  end
end

describe "resource(@location)" do 
  describe "a successful DELETE", :given => "a location exists" do
     before(:each) do
       @response = request(resource(Location.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:locations))
     end

   end
end

describe "resource(:locations, :new)" do
  before(:each) do
    @response = request(resource(:locations, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@location, :edit)", :given => "a location exists" do
  before(:each) do
    @response = request(resource(Location.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@location)", :given => "a location exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Location.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @location = Location.first
      @response = request(resource(@location), :method => "PUT", 
        :params => { :location => {:id => @location.id} })
    end
  
    it "redirect to the location show action" do
      @response.should redirect_to(resource(@location))
    end
  end
  
end

