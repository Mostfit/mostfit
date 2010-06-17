require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a account_type exists" do
  AccountType.all.destroy!
  request(resource(:account_types), :method => "POST", 
    :params => { :account_type => { :id => nil }})
end

describe "resource(:account_types)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:account_types))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of account_types" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a account_type exists" do
    before(:each) do
      @response = request(resource(:account_types))
    end
    
    it "has a list of account_types" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      AccountType.all.destroy!
      @response = request(resource(:account_types), :method => "POST", 
        :params => { :account_type => { :id => nil }})
    end
    
    it "redirects to resource(:account_types)" do
      @response.should redirect_to(resource(AccountType.first), :message => {:notice => "account_type was successfully created"})
    end
    
  end
end

describe "resource(@account_type)" do 
  describe "a successful DELETE", :given => "a account_type exists" do
     before(:each) do
       @response = request(resource(AccountType.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:account_types))
     end

   end
end

describe "resource(:account_types, :new)" do
  before(:each) do
    @response = request(resource(:account_types, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@account_type, :edit)", :given => "a account_type exists" do
  before(:each) do
    @response = request(resource(AccountType.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@account_type)", :given => "a account_type exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(AccountType.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @account_type = AccountType.first
      @response = request(resource(@account_type), :method => "PUT", 
        :params => { :account_type => {:id => @account_type.id} })
    end
  
    it "redirect to the account_type show action" do
      @response.should redirect_to(resource(@account_type))
    end
  end
  
end

