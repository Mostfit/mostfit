require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a area exists" do
  Area.all.destroy!
  request(resource(:areas), :method => "POST", 
    :params => { :area => { :id => nil }})
end

describe "resource(:areas)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:areas))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of areas" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a area exists" do
    before(:each) do
      @response = request(resource(:areas))
    end
    
    it "has a list of areas" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Area.all.destroy!
      @response = request(resource(:areas), :method => "POST", 
        :params => { :area => { :id => nil }})
    end
    
    it "redirects to resource(:areas)" do
      @response.should redirect_to(resource(Area.first), :message => {:notice => "area was successfully created"})
    end
    
  end
end

describe "resource(@area)" do 
  describe "a successful DELETE", :given => "a area exists" do
     before(:each) do
       @response = request(resource(Area.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:areas))
     end

   end
end

describe "resource(:areas, :new)" do
  before(:each) do
    @response = request(resource(:areas, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@area, :edit)", :given => "a area exists" do
  before(:each) do
    @response = request(resource(Area.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@area)", :given => "a area exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Area.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @area = Area.first
      @response = request(resource(@area), :method => "PUT", 
        :params => { :area => {:id => @area.id} })
    end
  
    it "redirect to the area show action" do
      @response.should redirect_to(resource(@area))
    end
  end
  
end

