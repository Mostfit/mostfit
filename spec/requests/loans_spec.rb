require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a loan exists" do
  Loan.all.destroy!
  request(resource(:loans), :method => "POST", 
    :params => { :loan => { :id => nil }})
end

describe "resource(:loans)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:loans))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of loans" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a loan exists" do
    before(:each) do
      @response = request(resource(:loans))
    end
    
    it "has a list of loans" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Loan.all.destroy!
      @response = request(resource(:loans), :method => "POST", 
        :params => { :loan => { :id => nil }})
    end
    
    it "redirects to resource(:loans)" do
      @response.should redirect_to(resource(Loan.first), :message => {:notice => "loan was successfully created"})
    end
    
  end
end

describe "resource(@loan)" do 
  describe "a successful DELETE", :given => "a loan exists" do
     before(:each) do
       @response = request(resource(Loan.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:loans))
     end

   end
end

describe "resource(:loans, :new)" do
  before(:each) do
    @response = request(resource(:loans, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@loan, :edit)", :given => "a loan exists" do
  before(:each) do
    @response = request(resource(Loan.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@loan)", :given => "a loan exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Loan.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @loan = Loan.first
      @response = request(resource(@loan), :method => "PUT", 
        :params => { :loan => {:id => @loan.id} })
    end
  
    it "redirect to the article show action" do
      @response.should redirect_to(resource(@loan))
    end
  end
  
end

