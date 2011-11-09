require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a checker exists" do
  Checker.all.destroy!
  request(resource(:checkers), :method => "POST", 
    :params => { :checker => { :id => nil }})
end

describe "resource(:checkers)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:checkers))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of checkers" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a checker exists" do
    before(:each) do
      @response = request(resource(:checkers))
    end
    
    it "has a list of checkers" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Checker.all.destroy!
      @response = request(resource(:checkers), :method => "POST", 
        :params => { :checker => { :id => nil }})
    end
    
    it "redirects to resource(:checkers)" do
      @response.should redirect_to(resource(Checker.first), :message => {:notice => "checker was successfully created"})
    end
    
  end
end

describe "resource(@checker)" do 
  describe "a successful DELETE", :given => "a checker exists" do
     before(:each) do
       @response = request(resource(Checker.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:checkers))
     end

   end
end

describe "resource(:checkers, :new)" do
  before(:each) do
    @response = request(resource(:checkers, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@checker, :edit)", :given => "a checker exists" do
  before(:each) do
    @response = request(resource(Checker.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@checker)", :given => "a checker exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Checker.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @checker = Checker.first
      @response = request(resource(@checker), :method => "PUT", 
        :params => { :checker => {:id => @checker.id} })
    end
  
    it "redirect to the checker show action" do
      @response.should redirect_to(resource(@checker))
    end
  end
  
end

