require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a payment exists" do
  Payment.all.destroy!
  request(resource(:payments), :method => "POST", 
    :params => { :payment => { :id => nil }})
end

describe "resource(:payments)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:payments))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of payments" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a payment exists" do
    before(:each) do
      @response = request(resource(:payments))
    end
    
    it "has a list of payments" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Payment.all.destroy!
      @response = request(resource(:payments), :method => "POST", 
        :params => { :payment => { :id => nil }})
    end
    
    it "redirects to resource(:payments)" do
      @response.should redirect_to(resource(Payment.first), :message => {:notice => "payment was successfully created"})
    end
    
  end
end

describe "resource(@payment)" do 
  describe "a successful DELETE", :given => "a payment exists" do
     before(:each) do
       @response = request(resource(Payment.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:payments))
     end

   end
end

describe "resource(:payments, :new)" do
  before(:each) do
    @response = request(resource(:payments, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@payment, :edit)", :given => "a payment exists" do
  before(:each) do
    @response = request(resource(Payment.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@payment)", :given => "a payment exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Payment.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @payment = Payment.first
      @response = request(resource(@payment), :method => "PUT", 
        :params => { :payment => {:id => @payment.id} })
    end
  
    it "redirect to the article show action" do
      @response.should redirect_to(resource(@payment))
    end
  end
  
end

