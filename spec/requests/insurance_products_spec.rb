require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a insurance_product exists" do
  InsuranceProduct.all.destroy!
  request(resource(:insurance_products), :method => "POST", 
    :params => { :insurance_product => { :id => nil }})
end

describe "resource(:insurance_products)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:insurance_products))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of insurance_products" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a insurance_product exists" do
    before(:each) do
      @response = request(resource(:insurance_products))
    end
    
    it "has a list of insurance_products" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      InsuranceProduct.all.destroy!
      @response = request(resource(:insurance_products), :method => "POST", 
        :params => { :insurance_product => { :id => nil }})
    end
    
    it "redirects to resource(:insurance_products)" do
      @response.should redirect_to(resource(InsuranceProduct.first), :message => {:notice => "insurance_product was successfully created"})
    end
    
  end
end

describe "resource(@insurance_product)" do 
  describe "a successful DELETE", :given => "a insurance_product exists" do
     before(:each) do
       @response = request(resource(InsuranceProduct.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:insurance_products))
     end

   end
end

describe "resource(:insurance_products, :new)" do
  before(:each) do
    @response = request(resource(:insurance_products, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@insurance_product, :edit)", :given => "a insurance_product exists" do
  before(:each) do
    @response = request(resource(InsuranceProduct.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@insurance_product)", :given => "a insurance_product exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(InsuranceProduct.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @insurance_product = InsuranceProduct.first
      @response = request(resource(@insurance_product), :method => "PUT", 
        :params => { :insurance_product => {:id => @insurance_product.id} })
    end
  
    it "redirect to the insurance_product show action" do
      @response.should redirect_to(resource(@insurance_product))
    end
  end
  
end

