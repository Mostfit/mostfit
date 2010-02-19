require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a insurance_company exists" do
  InsuranceCompany.all.destroy!
  request(resource(:insurance_companies), :method => "POST", 
    :params => { :insurance_company => { :id => nil }})
end

describe "resource(:insurance_companies)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:insurance_companies))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of insurance_companies" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a insurance_company exists" do
    before(:each) do
      @response = request(resource(:insurance_companies))
    end
    
    it "has a list of insurance_companies" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      InsuranceCompany.all.destroy!
      @response = request(resource(:insurance_companies), :method => "POST", 
        :params => { :insurance_company => { :id => nil }})
    end
    
    it "redirects to resource(:insurance_companies)" do
      @response.should redirect_to(resource(InsuranceCompany.first), :message => {:notice => "insurance_company was successfully created"})
    end
    
  end
end

describe "resource(@insurance_company)" do 
  describe "a successful DELETE", :given => "a insurance_company exists" do
     before(:each) do
       @response = request(resource(InsuranceCompany.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:insurance_companies))
     end

   end
end

describe "resource(:insurance_companies, :new)" do
  before(:each) do
    @response = request(resource(:insurance_companies, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@insurance_company, :edit)", :given => "a insurance_company exists" do
  before(:each) do
    @response = request(resource(InsuranceCompany.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@insurance_company)", :given => "a insurance_company exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(InsuranceCompany.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @insurance_company = InsuranceCompany.first
      @response = request(resource(@insurance_company), :method => "PUT", 
        :params => { :insurance_company => {:id => @insurance_company.id} })
    end
  
    it "redirect to the insurance_company show action" do
      @response.should redirect_to(resource(@insurance_company))
    end
  end
  
end

