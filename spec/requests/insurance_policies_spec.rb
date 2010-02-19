require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a insurance_policy exists" do
  InsurancePolicy.all.destroy!
  request(resource(:insurance_policies), :method => "POST", 
    :params => { :insurance_policy => { :id => nil }})
end

describe "resource(:insurance_policies)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:insurance_policies))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of insurance_policies" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a insurance_policy exists" do
    before(:each) do
      @response = request(resource(:insurance_policies))
    end
    
    it "has a list of insurance_policies" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      InsurancePolicy.all.destroy!
      @response = request(resource(:insurance_policies), :method => "POST", 
        :params => { :insurance_policy => { :id => nil }})
    end
    
    it "redirects to resource(:insurance_policies)" do
      @response.should redirect_to(resource(InsurancePolicy.first), :message => {:notice => "insurance_policy was successfully created"})
    end
    
  end
end

describe "resource(@insurance_policy)" do 
  describe "a successful DELETE", :given => "a insurance_policy exists" do
     before(:each) do
       @response = request(resource(InsurancePolicy.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:insurance_policies))
     end

   end
end

describe "resource(:insurance_policies, :new)" do
  before(:each) do
    @response = request(resource(:insurance_policies, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@insurance_policy, :edit)", :given => "a insurance_policy exists" do
  before(:each) do
    @response = request(resource(InsurancePolicy.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@insurance_policy)", :given => "a insurance_policy exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(InsurancePolicy.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @insurance_policy = InsurancePolicy.first
      @response = request(resource(@insurance_policy), :method => "PUT", 
        :params => { :insurance_policy => {:id => @insurance_policy.id} })
    end
  
    it "redirect to the insurance_policy show action" do
      @response.should redirect_to(resource(@insurance_policy))
    end
  end
  
end

