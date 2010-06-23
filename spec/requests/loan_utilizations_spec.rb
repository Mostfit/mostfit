require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a loan_utilization exists" do
  LoanUtilization.all.destroy!
  request(resource(:loan_utilizations), :method => "POST", 
    :params => { :loan_utilization => { :id => nil }})
end

describe "resource(:loan_utilizations)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:loan_utilizations))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of loan_utilizations" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a loan_utilization exists" do
    before(:each) do
      @response = request(resource(:loan_utilizations))
    end
    
    it "has a list of loan_utilizations" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      LoanUtilization.all.destroy!
      @response = request(resource(:loan_utilizations), :method => "POST", 
        :params => { :loan_utilization => { :id => nil }})
    end
    
    it "redirects to resource(:loan_utilizations)" do
      @response.should redirect_to(resource(LoanUtilization.first), :message => {:notice => "loan_utilization was successfully created"})
    end
    
  end
end

describe "resource(@loan_utilization)" do 
  describe "a successful DELETE", :given => "a loan_utilization exists" do
     before(:each) do
       @response = request(resource(LoanUtilization.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:loan_utilizations))
     end

   end
end

describe "resource(:loan_utilizations, :new)" do
  before(:each) do
    @response = request(resource(:loan_utilizations, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@loan_utilization, :edit)", :given => "a loan_utilization exists" do
  before(:each) do
    @response = request(resource(LoanUtilization.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@loan_utilization)", :given => "a loan_utilization exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(LoanUtilization.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @loan_utilization = LoanUtilization.first
      @response = request(resource(@loan_utilization), :method => "PUT", 
        :params => { :loan_utilization => {:id => @loan_utilization.id} })
    end
  
    it "redirect to the loan_utilization show action" do
      @response.should redirect_to(resource(@loan_utilization))
    end
  end
  
end

