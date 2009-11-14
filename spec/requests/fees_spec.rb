require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a fee exists" do
  Fee.all.destroy!
  request(resource(:fees), :method => "POST", 
    :params => { :fee => { :id => nil }})
end

describe "resource(:fees)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:fees))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of fees" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a fee exists" do
    before(:each) do
      @response = request(resource(:fees))
    end
    
    it "has a list of fees" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Fee.all.destroy!
      @response = request(resource(:fees), :method => "POST", 
        :params => { :fee => { :id => nil }})
    end
    
    it "redirects to resource(:fees)" do
      @response.should redirect_to(resource(Fee.first), :message => {:notice => "fee was successfully created"})
    end
    
  end
end

describe "resource(@fee)" do 
  describe "a successful DELETE", :given => "a fee exists" do
     before(:each) do
       @response = request(resource(Fee.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:fees))
     end

   end
end

describe "resource(:fees, :new)" do
  before(:each) do
    @response = request(resource(:fees, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@fee, :edit)", :given => "a fee exists" do
  before(:each) do
    @response = request(resource(Fee.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@fee)", :given => "a fee exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Fee.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @fee = Fee.first
      @response = request(resource(@fee), :method => "PUT", 
        :params => { :fee => {:id => @fee.id} })
    end
  
    it "redirect to the fee show action" do
      @response.should redirect_to(resource(@fee))
    end
  end
  
end

