require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a api_access exists" do
  ApiAccess.all.destroy!
  request(resource(:api_accesses), :method => "POST", 
    :params => { :api_access => { :id => nil }})
end

describe "resource(:api_accesses)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:api_accesses))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of api_accesses" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a api_access exists" do
    before(:each) do
      @response = request(resource(:api_accesses))
    end
    
    it "has a list of api_accesses" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      ApiAccess.all.destroy!
      @response = request(resource(:api_accesses), :method => "POST", 
        :params => { :api_access => { :id => nil }})
    end
    
    it "redirects to resource(:api_accesses)" do
      @response.should redirect_to(resource(ApiAccess.first), :message => {:notice => "api_access was successfully created"})
    end
    
  end
end

describe "resource(@api_access)" do 
  describe "a successful DELETE", :given => "a api_access exists" do
     before(:each) do
       @response = request(resource(ApiAccess.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:api_accesses))
     end

   end
end

describe "resource(:api_accesses, :new)" do
  before(:each) do
    @response = request(resource(:api_accesses, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@api_access, :edit)", :given => "a api_access exists" do
  before(:each) do
    @response = request(resource(ApiAccess.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@api_access)", :given => "a api_access exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(ApiAccess.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @api_access = ApiAccess.first
      @response = request(resource(@api_access), :method => "PUT", 
        :params => { :api_access => {:id => @api_access.id} })
    end
  
    it "redirect to the api_access show action" do
      @response.should redirect_to(resource(@api_access))
    end
  end
  
end

