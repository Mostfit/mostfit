require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a accounting_period exists" do
  AccountingPeriod.all.destroy!
  request(resource(:accounting_periods), :method => "POST", 
    :params => { :accounting_period => { :id => nil }})
end

describe "resource(:accounting_periods)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:accounting_periods))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of accounting_periods" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a accounting_period exists" do
    before(:each) do
      @response = request(resource(:accounting_periods))
    end
    
    it "has a list of accounting_periods" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      AccountingPeriod.all.destroy!
      @response = request(resource(:accounting_periods), :method => "POST", 
        :params => { :accounting_period => { :id => nil }})
    end
    
    it "redirects to resource(:accounting_periods)" do
      @response.should redirect_to(resource(AccountingPeriod.first), :message => {:notice => "accounting_period was successfully created"})
    end
    
  end
end

describe "resource(@accounting_period)" do 
  describe "a successful DELETE", :given => "a accounting_period exists" do
     before(:each) do
       @response = request(resource(AccountingPeriod.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:accounting_periods))
     end

   end
end

describe "resource(:accounting_periods, :new)" do
  before(:each) do
    @response = request(resource(:accounting_periods, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@accounting_period, :edit)", :given => "a accounting_period exists" do
  before(:each) do
    @response = request(resource(AccountingPeriod.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@accounting_period)", :given => "a accounting_period exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(AccountingPeriod.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @accounting_period = AccountingPeriod.first
      @response = request(resource(@accounting_period), :method => "PUT", 
        :params => { :accounting_period => {:id => @accounting_period.id} })
    end
  
    it "redirect to the accounting_period show action" do
      @response.should redirect_to(resource(@accounting_period))
    end
  end
  
end

