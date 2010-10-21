require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a rule exists" do
  Rule.all.destroy!
  request(resource(:rules), :method => "POST", 
    :params => { :rule => { :id => nil }})
end

describe "resource(:rules)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:rules))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of rules" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a rule exists" do
    before(:each) do
      @response = request(resource(:rules))
    end
    
    it "has a list of rules" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Rule.all.destroy!
      @response = request(resource(:rules), :method => "POST", 
        :params => { :rule => { :id => nil }})
    end
    
    it "redirects to resource(:rules)" do
      @response.should redirect_to(resource(Rule.first), :message => {:notice => "rule was successfully created"})
    end
    
  end
end

describe "resource(@rule)" do 
  describe "a successful DELETE", :given => "a rule exists" do
     before(:each) do
       @response = request(resource(Rule.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:rules))
     end

   end
end

describe "resource(:rules, :new)" do
  before(:each) do
    @response = request(resource(:rules, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@rule, :edit)", :given => "a rule exists" do
  before(:each) do
    @response = request(resource(Rule.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@rule)", :given => "a rule exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Rule.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @rule = Rule.first
      @response = request(resource(@rule), :method => "PUT", 
        :params => { :rule => {:id => @rule.id} })
    end
  
    it "redirect to the rule show action" do
      @response.should redirect_to(resource(@rule))
    end
  end
  
end

