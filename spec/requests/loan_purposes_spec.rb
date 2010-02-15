require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a loan_purpose exists" do
  LoanPurpose.all.destroy!
  request(resource(:loan_purposes), :method => "POST", 
    :params => { :loan_purpose => { :id => nil }})
end

describe "resource(:loan_purposes)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:loan_purposes))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of loan_purposes" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a loan_purpose exists" do
    before(:each) do
      @response = request(resource(:loan_purposes))
    end
    
    it "has a list of loan_purposes" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      LoanPurpose.all.destroy!
      @response = request(resource(:loan_purposes), :method => "POST", 
        :params => { :loan_purpose => { :id => nil }})
    end
    
    it "redirects to resource(:loan_purposes)" do
      @response.should redirect_to(resource(LoanPurpose.first), :message => {:notice => "loan_purpose was successfully created"})
    end
    
  end
end

describe "resource(@loan_purpose)" do 
  describe "a successful DELETE", :given => "a loan_purpose exists" do
     before(:each) do
       @response = request(resource(LoanPurpose.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:loan_purposes))
     end

   end
end

describe "resource(:loan_purposes, :new)" do
  before(:each) do
    @response = request(resource(:loan_purposes, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@loan_purpose, :edit)", :given => "a loan_purpose exists" do
  before(:each) do
    @response = request(resource(LoanPurpose.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@loan_purpose)", :given => "a loan_purpose exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(LoanPurpose.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @loan_purpose = LoanPurpose.first
      @response = request(resource(@loan_purpose), :method => "PUT", 
        :params => { :loan_purpose => {:id => @loan_purpose.id} })
    end
  
    it "redirect to the loan_purpose show action" do
      @response.should redirect_to(resource(@loan_purpose))
    end
  end
  
end

