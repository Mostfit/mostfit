require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a target exists" do
  Target.all.destroy!
  request(resource(:targets), :method => "POST", 
    :params => { :target => { :id => nil }})
end

describe "resource(:targets)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:targets))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of targets" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a target exists" do
    before(:each) do
      @response = request(resource(:targets))
    end
    
    it "has a list of targets" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Target.all.destroy!
      @response = request(resource(:targets), :method => "POST", 
        :params => { :target => { :id => nil }})
    end
    
    it "redirects to resource(:targets)" do
      @response.should redirect_to(resource(Target.first), :message => {:notice => "target was successfully created"})
    end
    
  end
end

describe "resource(@target)" do 
  describe "a successful DELETE", :given => "a target exists" do
     before(:each) do
       @response = request(resource(Target.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:targets))
     end

   end
end

describe "resource(:targets, :new)" do
  before(:each) do
    @response = request(resource(:targets, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@target, :edit)", :given => "a target exists" do
  before(:each) do
    @response = request(resource(Target.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@target)", :given => "a target exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Target.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @target = Target.first
      @response = request(resource(@target), :method => "PUT", 
        :params => { :target => {:id => @target.id} })
    end
  
    it "redirect to the target show action" do
      @response.should redirect_to(resource(@target))
    end
  end
  
end

