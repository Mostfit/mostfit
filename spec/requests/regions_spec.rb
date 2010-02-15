require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a region exists" do
  Region.all.destroy!
  request(resource(:regions), :method => "POST", 
    :params => { :region => { :id => nil }})
end

describe "resource(:regions)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:regions))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of regions" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a region exists" do
    before(:each) do
      @response = request(resource(:regions))
    end
    
    it "has a list of regions" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Region.all.destroy!
      @response = request(resource(:regions), :method => "POST", 
        :params => { :region => { :id => nil }})
    end
    
    it "redirects to resource(:regions)" do
      @response.should redirect_to(resource(Region.first), :message => {:notice => "region was successfully created"})
    end
    
  end
end

describe "resource(@region)" do 
  describe "a successful DELETE", :given => "a region exists" do
     before(:each) do
       @response = request(resource(Region.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:regions))
     end

   end
end

describe "resource(:regions, :new)" do
  before(:each) do
    @response = request(resource(:regions, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@region, :edit)", :given => "a region exists" do
  before(:each) do
    @response = request(resource(Region.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@region)", :given => "a region exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Region.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @region = Region.first
      @response = request(resource(@region), :method => "PUT", 
        :params => { :region => {:id => @region.id} })
    end
  
    it "redirect to the region show action" do
      @response.should redirect_to(resource(@region))
    end
  end
  
end

