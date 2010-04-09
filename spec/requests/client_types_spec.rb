require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a client_type exists" do
  ClientType.all.destroy!
  request(resource(:client_types), :method => "POST", 
    :params => { :client_type => { :id => nil }})
end

describe "resource(:client_types)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:client_types))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of client_types" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a client_type exists" do
    before(:each) do
      @response = request(resource(:client_types))
    end
    
    it "has a list of client_types" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      ClientType.all.destroy!
      @response = request(resource(:client_types), :method => "POST", 
        :params => { :client_type => { :id => nil }})
    end
    
    it "redirects to resource(:client_types)" do
      @response.should redirect_to(resource(ClientType.first), :message => {:notice => "client_type was successfully created"})
    end
    
  end
end

describe "resource(@client_type)" do 
  describe "a successful DELETE", :given => "a client_type exists" do
     before(:each) do
       @response = request(resource(ClientType.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:client_types))
     end

   end
end

describe "resource(:client_types, :new)" do
  before(:each) do
    @response = request(resource(:client_types, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@client_type, :edit)", :given => "a client_type exists" do
  before(:each) do
    @response = request(resource(ClientType.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@client_type)", :given => "a client_type exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(ClientType.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @client_type = ClientType.first
      @response = request(resource(@client_type), :method => "PUT", 
        :params => { :client_type => {:id => @client_type.id} })
    end
  
    it "redirect to the client_type show action" do
      @response.should redirect_to(resource(@client_type))
    end
  end
  
end

