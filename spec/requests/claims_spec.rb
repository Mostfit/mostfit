require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a claim exists" do
  Claim.all.destroy!
  request(resource(:claims), :method => "POST", 
    :params => { :claim => { :id => nil }})
end

describe "resource(:claims)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:claims))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of claims" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a claim exists" do
    before(:each) do
      @response = request(resource(:claims))
    end
    
    it "has a list of claims" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Claim.all.destroy!
      @response = request(resource(:claims), :method => "POST", 
        :params => { :claim => { :id => nil }})
    end
    
    it "redirects to resource(:claims)" do
      @response.should redirect_to(resource(Claim.first), :message => {:notice => "claim was successfully created"})
    end
    
  end
end

describe "resource(@claim)" do 
  describe "a successful DELETE", :given => "a claim exists" do
     before(:each) do
       @response = request(resource(Claim.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:claims))
     end

   end
end

describe "resource(:claims, :new)" do
  before(:each) do
    @response = request(resource(:claims, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@claim, :edit)", :given => "a claim exists" do
  before(:each) do
    @response = request(resource(Claim.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@claim)", :given => "a claim exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Claim.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @claim = Claim.first
      @response = request(resource(@claim), :method => "PUT", 
        :params => { :claim => {:id => @claim.id} })
    end
  
    it "redirect to the claim show action" do
      @response.should redirect_to(resource(@claim))
    end
  end
  
end

