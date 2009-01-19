require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a client exists" do
  Client.all.destroy!
  request(resource(:clients), :method => "POST", 
    :params => { :client => { :id => nil }})
end

describe "resource(:clients)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:clients))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of clients" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a client exists" do
    before(:each) do
      @response = request(resource(:clients))
    end
    
    it "has a list of clients" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Client.all.destroy!
      @response = request(resource(:clients), :method => "POST", 
        :params => { :client => { :id => nil }})
    end
    
    it "redirects to resource(:clients)" do
      @response.should redirect_to(resource(Client.first), :message => {:notice => "client was successfully created"})
    end
    
  end
end

describe "resource(@client)" do 
  describe "a successful DELETE", :given => "a client exists" do
     before(:each) do
       @response = request(resource(Client.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:clients))
     end

   end
end

describe "resource(:clients, :new)" do
  before(:each) do
    @response = request(resource(:clients, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@client, :edit)", :given => "a client exists" do
  before(:each) do
    @response = request(resource(Client.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@client)", :given => "a client exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Client.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @client = Client.first
      @response = request(resource(@client), :method => "PUT", 
        :params => { :client => {:id => @client.id} })
    end
  
    it "redirect to the article show action" do
      @response.should redirect_to(resource(@client))
    end
  end
  
end

