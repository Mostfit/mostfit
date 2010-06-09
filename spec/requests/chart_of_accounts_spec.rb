require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a chart_of_account exists" do
  ChartOfAccount.all.destroy!
  request(resource(:chart_of_accounts), :method => "POST", 
    :params => { :chart_of_account => { :id => nil }})
end

describe "resource(:chart_of_accounts)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:chart_of_accounts))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of chart_of_accounts" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a chart_of_account exists" do
    before(:each) do
      @response = request(resource(:chart_of_accounts))
    end
    
    it "has a list of chart_of_accounts" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      ChartOfAccount.all.destroy!
      @response = request(resource(:chart_of_accounts), :method => "POST", 
        :params => { :chart_of_account => { :id => nil }})
    end
    
    it "redirects to resource(:chart_of_accounts)" do
      @response.should redirect_to(resource(ChartOfAccount.first), :message => {:notice => "chart_of_account was successfully created"})
    end
    
  end
end

describe "resource(@chart_of_account)" do 
  describe "a successful DELETE", :given => "a chart_of_account exists" do
     before(:each) do
       @response = request(resource(ChartOfAccount.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:chart_of_accounts))
     end

   end
end

describe "resource(:chart_of_accounts, :new)" do
  before(:each) do
    @response = request(resource(:chart_of_accounts, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@chart_of_account, :edit)", :given => "a chart_of_account exists" do
  before(:each) do
    @response = request(resource(ChartOfAccount.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@chart_of_account)", :given => "a chart_of_account exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(ChartOfAccount.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @chart_of_account = ChartOfAccount.first
      @response = request(resource(@chart_of_account), :method => "PUT", 
        :params => { :chart_of_account => {:id => @chart_of_account.id} })
    end
  
    it "redirect to the chart_of_account show action" do
      @response.should redirect_to(resource(@chart_of_account))
    end
  end
  
end

