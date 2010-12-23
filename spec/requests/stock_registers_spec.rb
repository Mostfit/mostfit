require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a stock_register exists" do
  StockRegister.all.destroy!
  request(resource(:stock_registers), :method => "POST", 
    :params => { :stock_register => { :id => nil }})
end

describe "resource(:stock_registers)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:stock_registers))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of stock_registers" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a stock_register exists" do
    before(:each) do
      @response = request(resource(:stock_registers))
    end
    
    it "has a list of stock_registers" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      StockRegister.all.destroy!
      @response = request(resource(:stock_registers), :method => "POST", 
        :params => { :stock_register => { :id => nil }})
    end
    
    it "redirects to resource(:stock_registers)" do
      @response.should redirect_to(resource(StockRegister.first), :message => {:notice => "stock_register was successfully created"})
    end
    
  end
end

describe "resource(@stock_register)" do 
  describe "a successful DELETE", :given => "a stock_register exists" do
     before(:each) do
       @response = request(resource(StockRegister.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:stock_registers))
     end

   end
end

describe "resource(:stock_registers, :new)" do
  before(:each) do
    @response = request(resource(:stock_registers, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@stock_register, :edit)", :given => "a stock_register exists" do
  before(:each) do
    @response = request(resource(StockRegister.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@stock_register)", :given => "a stock_register exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(StockRegister.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @stock_register = StockRegister.first
      @response = request(resource(@stock_register), :method => "PUT", 
        :params => { :stock_register => {:id => @stock_register.id} })
    end
  
    it "redirect to the stock_register show action" do
      @response.should redirect_to(resource(@stock_register))
    end
  end
  
end

