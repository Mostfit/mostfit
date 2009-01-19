require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a center exists" do
  Center.all.destroy!
  request(resource(:centers), :method => "POST", 
    :params => { :center => { :id => nil }})
end

describe "resource(:centers)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:centers))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of centers" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a center exists" do
    before(:each) do
      @response = request(resource(:centers))
    end
    
    it "has a list of centers" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Center.all.destroy!
      @response = request(resource(:centers), :method => "POST", 
        :params => { :center => { :id => nil }})
    end
    
    it "redirects to resource(:centers)" do
      @response.should redirect_to(resource(Center.first), :message => {:notice => "center was successfully created"})
    end
    
  end
end

describe "resource(@center)" do 
  describe "a successful DELETE", :given => "a center exists" do
     before(:each) do
       @response = request(resource(Center.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:centers))
     end

   end
end

describe "resource(:centers, :new)" do
  before(:each) do
    @response = request(resource(:centers, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@center, :edit)", :given => "a center exists" do
  before(:each) do
    @response = request(resource(Center.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@center)", :given => "a center exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Center.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @center = Center.first
      @response = request(resource(@center), :method => "PUT", 
        :params => { :center => {:id => @center.id} })
    end
  
    it "redirect to the article show action" do
      @response.should redirect_to(resource(@center))
    end
  end
  
end

