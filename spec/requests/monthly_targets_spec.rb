require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a monthly_target exists" do
  MonthlyTarget.all.destroy!
  request(resource(:monthly_targets), :method => "POST", 
    :params => { :monthly_target => { :id => nil }})
end

describe "resource(:monthly_targets)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:monthly_targets))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of monthly_targets" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a monthly_target exists" do
    before(:each) do
      @response = request(resource(:monthly_targets))
    end
    
    it "has a list of monthly_targets" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      MonthlyTarget.all.destroy!
      @response = request(resource(:monthly_targets), :method => "POST", 
        :params => { :monthly_target => { :id => nil }})
    end
    
    it "redirects to resource(:monthly_targets)" do
      @response.should redirect_to(resource(MonthlyTarget.first), :message => {:notice => "monthly_target was successfully created"})
    end
    
  end
end

describe "resource(@monthly_target)" do 
  describe "a successful DELETE", :given => "a monthly_target exists" do
     before(:each) do
       @response = request(resource(MonthlyTarget.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:monthly_targets))
     end

   end
end

describe "resource(:monthly_targets, :new)" do
  before(:each) do
    @response = request(resource(:monthly_targets, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@monthly_target, :edit)", :given => "a monthly_target exists" do
  before(:each) do
    @response = request(resource(MonthlyTarget.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@monthly_target)", :given => "a monthly_target exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(MonthlyTarget.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @monthly_target = MonthlyTarget.first
      @response = request(resource(@monthly_target), :method => "PUT", 
        :params => { :monthly_target => {:id => @monthly_target.id} })
    end
  
    it "redirect to the monthly_target show action" do
      @response.should redirect_to(resource(@monthly_target))
    end
  end
  
end

