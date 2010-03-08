require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a cgt exists" do
  Cgt.all.destroy!
  request(resource(:cgts), :method => "POST", 
    :params => { :cgt => { :id => nil }})
end

describe "resource(:cgts)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:cgts))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of cgts" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a cgt exists" do
    before(:each) do
      @response = request(resource(:cgts))
    end
    
    it "has a list of cgts" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Cgt.all.destroy!
      @response = request(resource(:cgts), :method => "POST", 
        :params => { :cgt => { :id => nil }})
    end
    
    it "redirects to resource(:cgts)" do
      @response.should redirect_to(resource(Cgt.first), :message => {:notice => "cgt was successfully created"})
    end
    
  end
end

describe "resource(@cgt)" do 
  describe "a successful DELETE", :given => "a cgt exists" do
     before(:each) do
       @response = request(resource(Cgt.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:cgts))
     end

   end
end

describe "resource(:cgts, :new)" do
  before(:each) do
    @response = request(resource(:cgts, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@cgt, :edit)", :given => "a cgt exists" do
  before(:each) do
    @response = request(resource(Cgt.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@cgt)", :given => "a cgt exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Cgt.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @cgt = Cgt.first
      @response = request(resource(@cgt), :method => "PUT", 
        :params => { :cgt => {:id => @cgt.id} })
    end
  
    it "redirect to the cgt show action" do
      @response.should redirect_to(resource(@cgt))
    end
  end
  
end

