require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a funder exists" do
  Funder.all.destroy!
  request(resource(:funders), :method => "POST", 
    :params => { :funder => { :id => nil }})
end

describe "resource(:funders)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:funders))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of funders" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a funder exists" do
    before(:each) do
      @response = request(resource(:funders))
    end
    
    it "has a list of funders" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Funder.all.destroy!
      @response = request(resource(:funders), :method => "POST", 
        :params => { :funder => { :id => nil }})
    end
    
    it "redirects to resource(:funders)" do
      @response.should redirect_to(resource(Funder.first), :message => {:notice => "funder was successfully created"})
    end
    
  end
end

describe "resource(@funder)" do 
  describe "a successful DELETE", :given => "a funder exists" do
     before(:each) do
       @response = request(resource(Funder.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:funders))
     end

   end
end

describe "resource(:funders, :new)" do
  before(:each) do
    @response = request(resource(:funders, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@funder, :edit)", :given => "a funder exists" do
  before(:each) do
    @response = request(resource(Funder.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@funder)", :given => "a funder exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Funder.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @funder = Funder.first
      @response = request(resource(@funder), :method => "PUT", 
        :params => { :funder => {:id => @funder.id} })
    end
  
    it "redirect to the funder show action" do
      @response.should redirect_to(resource(@funder))
    end
  end
  
end

