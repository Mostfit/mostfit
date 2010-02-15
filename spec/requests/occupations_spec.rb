require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a occupation exists" do
  Occupation.all.destroy!
  request(resource(:occupations), :method => "POST", 
    :params => { :occupation => { :id => nil }})
end

describe "resource(:occupations)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:occupations))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of occupations" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a occupation exists" do
    before(:each) do
      @response = request(resource(:occupations))
    end
    
    it "has a list of occupations" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Occupation.all.destroy!
      @response = request(resource(:occupations), :method => "POST", 
        :params => { :occupation => { :id => nil }})
    end
    
    it "redirects to resource(:occupations)" do
      @response.should redirect_to(resource(Occupation.first), :message => {:notice => "occupation was successfully created"})
    end
    
  end
end

describe "resource(@occupation)" do 
  describe "a successful DELETE", :given => "a occupation exists" do
     before(:each) do
       @response = request(resource(Occupation.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:occupations))
     end

   end
end

describe "resource(:occupations, :new)" do
  before(:each) do
    @response = request(resource(:occupations, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@occupation, :edit)", :given => "a occupation exists" do
  before(:each) do
    @response = request(resource(Occupation.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@occupation)", :given => "a occupation exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Occupation.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @occupation = Occupation.first
      @response = request(resource(@occupation), :method => "PUT", 
        :params => { :occupation => {:id => @occupation.id} })
    end
  
    it "redirect to the occupation show action" do
      @response.should redirect_to(resource(@occupation))
    end
  end
  
end

