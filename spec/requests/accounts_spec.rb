require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a account exists" do
  Account.all.destroy!
  request(resource(:accounts), :method => "POST", 
    :params => { :account => { :id => nil }})
end

describe "resource(:accounts)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:accounts))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of accounts" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a account exists" do
    before(:each) do
      @response = request(resource(:accounts))
    end
    
    it "has a list of accounts" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Account.all.destroy!
      @response = request(resource(:accounts), :method => "POST", 
        :params => { :account => { :id => nil }})
    end
    
    it "redirects to resource(:accounts)" do
      @response.should redirect_to(resource(Account.first), :message => {:notice => "account was successfully created"})
    end
    
  end
end

describe "resource(@account)" do 
  describe "a successful DELETE", :given => "a account exists" do
     before(:each) do
       @response = request(resource(Account.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:accounts))
     end

   end
end

describe "resource(:accounts, :new)" do
  before(:each) do
    @response = request(resource(:accounts, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@account, :edit)", :given => "a account exists" do
  before(:each) do
    @response = request(resource(Account.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@account)", :given => "a account exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Account.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @account = Account.first
      @response = request(resource(@account), :method => "PUT", 
        :params => { :account => {:id => @account.id} })
    end
  
    it "redirect to the account show action" do
      @response.should redirect_to(resource(@account))
    end
  end
  
end

