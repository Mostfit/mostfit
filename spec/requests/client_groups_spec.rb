require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a client_group exists" do
  ClientGroup.all.destroy!
  request(resource(:client_groups), :method => "POST", 
    :params => { :client_group => { :id => nil }})
end

describe "resource(:client_groups)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:client_groups))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of client_groups" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a client_group exists" do
    before(:each) do
      @response = request(resource(:client_groups))
    end
    
    it "has a list of client_groups" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      ClientGroup.all.destroy!
      @response = request(resource(:client_groups), :method => "POST", 
        :params => { :client_group => { :id => nil }})
    end
    
    it "redirects to resource(:client_groups)" do
      @response.should redirect_to(resource(ClientGroup.first), :message => {:notice => "client_group was successfully created"})
    end
    
  end
end

describe "resource(@client_group)" do 
  describe "a successful DELETE", :given => "a client_group exists" do
     before(:each) do
       @response = request(resource(ClientGroup.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:client_groups))
     end

   end
end

describe "resource(:client_groups, :new)" do
  before(:each) do
    @response = request(resource(:client_groups, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@client_group, :edit)", :given => "a client_group exists" do
  before(:each) do
    @response = request(resource(ClientGroup.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@client_group)", :given => "a client_group exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(ClientGroup.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @client_group = ClientGroup.first
      @response = request(resource(@client_group), :method => "PUT", 
        :params => { :client_group => {:id => @client_group.id} })
    end
  
    it "redirect to the client_group show action" do
      @response.should redirect_to(resource(@client_group))
    end
  end
  
end

