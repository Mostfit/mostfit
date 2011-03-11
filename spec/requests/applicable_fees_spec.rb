require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a applicable_fee exists" do
  ApplicableFee.all.destroy!
  request(resource(:applicable_fees), :method => "POST", 
    :params => { :applicable_fee => { :id => nil }})
end

describe "resource(:applicable_fees)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:applicable_fees))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of applicable_fees" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a applicable_fee exists" do
    before(:each) do
      @response = request(resource(:applicable_fees))
    end
    
    it "has a list of applicable_fees" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      ApplicableFee.all.destroy!
      @response = request(resource(:applicable_fees), :method => "POST", 
        :params => { :applicable_fee => { :id => nil }})
    end
    
    it "redirects to resource(:applicable_fees)" do
      @response.should redirect_to(resource(ApplicableFee.first), :message => {:notice => "applicable_fee was successfully created"})
    end
    
  end
end

describe "resource(@applicable_fee)" do 
  describe "a successful DELETE", :given => "a applicable_fee exists" do
     before(:each) do
       @response = request(resource(ApplicableFee.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:applicable_fees))
     end

   end
end

describe "resource(:applicable_fees, :new)" do
  before(:each) do
    @response = request(resource(:applicable_fees, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@applicable_fee, :edit)", :given => "a applicable_fee exists" do
  before(:each) do
    @response = request(resource(ApplicableFee.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@applicable_fee)", :given => "a applicable_fee exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(ApplicableFee.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @applicable_fee = ApplicableFee.first
      @response = request(resource(@applicable_fee), :method => "PUT", 
        :params => { :applicable_fee => {:id => @applicable_fee.id} })
    end
  
    it "redirect to the applicable_fee show action" do
      @response.should redirect_to(resource(@applicable_fee))
    end
  end
  
end

