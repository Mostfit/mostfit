require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a grt exists" do
  Grt.all.destroy!
  request(resource(:grts), :method => "POST", 
    :params => { :grt => { :id => nil }})
end

describe "resource(:grts)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:grts))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of grts" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a grt exists" do
    before(:each) do
      @response = request(resource(:grts))
    end
    
    it "has a list of grts" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Grt.all.destroy!
      @response = request(resource(:grts), :method => "POST", 
        :params => { :grt => { :id => nil }})
    end
    
    it "redirects to resource(:grts)" do
      @response.should redirect_to(resource(Grt.first), :message => {:notice => "grt was successfully created"})
    end
    
  end
end

describe "resource(@grt)" do 
  describe "a successful DELETE", :given => "a grt exists" do
     before(:each) do
       @response = request(resource(Grt.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:grts))
     end

   end
end

describe "resource(:grts, :new)" do
  before(:each) do
    @response = request(resource(:grts, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@grt, :edit)", :given => "a grt exists" do
  before(:each) do
    @response = request(resource(Grt.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@grt)", :given => "a grt exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Grt.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @grt = Grt.first
      @response = request(resource(@grt), :method => "PUT", 
        :params => { :grt => {:id => @grt.id} })
    end
  
    it "redirect to the grt show action" do
      @response.should redirect_to(resource(@grt))
    end
  end
  
end

