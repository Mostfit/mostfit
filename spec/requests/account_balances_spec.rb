require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a account_balance exists" do
  AccountBalance.all.destroy!
  request(resource(:account_balances), :method => "POST", 
    :params => { :account_balance => { :id => nil }})
end

describe "resource(:account_balances)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:account_balances))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of account_balances" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a account_balance exists" do
    before(:each) do
      @response = request(resource(:account_balances))
    end
    
    it "has a list of account_balances" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      AccountBalance.all.destroy!
      @response = request(resource(:account_balances), :method => "POST", 
        :params => { :account_balance => { :id => nil }})
    end
    
    it "redirects to resource(:account_balances)" do
      @response.should redirect_to(resource(AccountBalance.first), :message => {:notice => "account_balance was successfully created"})
    end
    
  end
end

describe "resource(@account_balance)" do 
  describe "a successful DELETE", :given => "a account_balance exists" do
     before(:each) do
       @response = request(resource(AccountBalance.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:account_balances))
     end

   end
end

describe "resource(:account_balances, :new)" do
  before(:each) do
    @response = request(resource(:account_balances, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@account_balance, :edit)", :given => "a account_balance exists" do
  before(:each) do
    @response = request(resource(AccountBalance.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@account_balance)", :given => "a account_balance exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(AccountBalance.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @account_balance = AccountBalance.first
      @response = request(resource(@account_balance), :method => "PUT", 
        :params => { :account_balance => {:id => @account_balance.id} })
    end
  
    it "redirect to the account_balance show action" do
      @response.should redirect_to(resource(@account_balance))
    end
  end
  
end

