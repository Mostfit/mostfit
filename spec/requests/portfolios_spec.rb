require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a portfolio exists" do
  Portfolio.all.destroy!
  request(resource(:portfolios), :method => "POST", 
    :params => { :portfolio => { :id => nil }})
end

describe "resource(:portfolios)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:portfolios))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of portfolios" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a portfolio exists" do
    before(:each) do
      @response = request(resource(:portfolios))
    end
    
    it "has a list of portfolios" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Portfolio.all.destroy!
      @response = request(resource(:portfolios), :method => "POST", 
        :params => { :portfolio => { :id => nil }})
    end
    
    it "redirects to resource(:portfolios)" do
      @response.should redirect_to(resource(Portfolio.first), :message => {:notice => "portfolio was successfully created"})
    end
    
  end
end

describe "resource(@portfolio)" do 
  describe "a successful DELETE", :given => "a portfolio exists" do
     before(:each) do
       @response = request(resource(Portfolio.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:portfolios))
     end

   end
end

describe "resource(:portfolios, :new)" do
  before(:each) do
    @response = request(resource(:portfolios, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@portfolio, :edit)", :given => "a portfolio exists" do
  before(:each) do
    @response = request(resource(Portfolio.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@portfolio)", :given => "a portfolio exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Portfolio.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @portfolio = Portfolio.first
      @response = request(resource(@portfolio), :method => "PUT", 
        :params => { :portfolio => {:id => @portfolio.id} })
    end
  
    it "redirect to the portfolio show action" do
      @response.should redirect_to(resource(@portfolio))
    end
  end
  
end

