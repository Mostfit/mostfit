require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a permission exists" do
  Permission.all.destroy!
  request(resource(:permissions), :method => "POST", 
    :params => { :permission => { :id => nil }})
end

describe "resource(:permissions)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:permissions))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of permissions" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a permission exists" do
    before(:each) do
      @response = request(resource(:permissions))
    end
    
    it "has a list of permissions" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Permission.all.destroy!
      @response = request(resource(:permissions), :method => "POST", 
        :params => { :permission => { :id => nil }})
    end
    
    it "redirects to resource(:permissions)" do
      @response.should redirect_to(resource(Permission.first), :message => {:notice => "permission was successfully created"})
    end
    
  end
end

describe "resource(@permission)" do 
  describe "a successful DELETE", :given => "a permission exists" do
     before(:each) do
       @response = request(resource(Permission.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:permissions))
     end

   end
end

describe "resource(:permissions, :new)" do
  before(:each) do
    @response = request(resource(:permissions, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@permission, :edit)", :given => "a permission exists" do
  before(:each) do
    @response = request(resource(Permission.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@permission)", :given => "a permission exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Permission.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @permission = Permission.first
      @response = request(resource(@permission), :method => "PUT", 
        :params => { :permission => {:id => @permission.id} })
    end
  
    it "redirect to the article show action" do
      @response.should redirect_to(resource(@permission))
    end
  end
  
end

