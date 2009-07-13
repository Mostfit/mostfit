require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a loan_type exists" do
  LoanType.all.destroy!
  request(resource(:loan_types), :method => "POST", 
    :params => { :loan_type => { :id => nil }})
end

describe "resource(:loan_types)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:loan_types))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of loan_types" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a loan_type exists" do
    before(:each) do
      @response = request(resource(:loan_types))
    end
    
    it "has a list of loan_types" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      LoanType.all.destroy!
      @response = request(resource(:loan_types), :method => "POST", 
        :params => { :loan_type => { :id => nil }})
    end
    
    it "redirects to resource(:loan_types)" do
      @response.should redirect_to(resource(LoanType.first), :message => {:notice => "loan_type was successfully created"})
    end
    
  end
end

describe "resource(@loan_type)" do 
  describe "a successful DELETE", :given => "a loan_type exists" do
     before(:each) do
       @response = request(resource(LoanType.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:loan_types))
     end

   end
end

describe "resource(:loan_types, :new)" do
  before(:each) do
    @response = request(resource(:loan_types, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@loan_type, :edit)", :given => "a loan_type exists" do
  before(:each) do
    @response = request(resource(LoanType.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@loan_type)", :given => "a loan_type exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(LoanType.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @loan_type = LoanType.first
      @response = request(resource(@loan_type), :method => "PUT", 
        :params => { :loan_type => {:id => @loan_type.id} })
    end
  
    it "redirect to the loan_type show action" do
      @response.should redirect_to(resource(@loan_type))
    end
  end
  
end

