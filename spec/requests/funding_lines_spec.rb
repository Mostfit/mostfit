require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a funding_line exists" do
  FundingLine.all.destroy!
  request(resource(:funding_lines), :method => "POST", 
    :params => { :funding_line => { :id => nil }})
end

describe "resource(:funding_lines)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:funding_lines))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of funding_lines" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a funding_line exists" do
    before(:each) do
      @response = request(resource(:funding_lines))
    end
    
    it "has a list of funding_lines" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      FundingLine.all.destroy!
      @response = request(resource(:funding_lines), :method => "POST", 
        :params => { :funding_line => { :id => nil }})
    end
    
    it "redirects to resource(:funding_lines)" do
      @response.should redirect_to(resource(FundingLine.first), :message => {:notice => "funding_line was successfully created"})
    end
    
  end
end

describe "resource(@funding_line)" do 
  describe "a successful DELETE", :given => "a funding_line exists" do
     before(:each) do
       @response = request(resource(FundingLine.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:funding_lines))
     end

   end
end

describe "resource(:funding_lines, :new)" do
  before(:each) do
    @response = request(resource(:funding_lines, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@funding_line, :edit)", :given => "a funding_line exists" do
  before(:each) do
    @response = request(resource(FundingLine.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@funding_line)", :given => "a funding_line exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(FundingLine.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @funding_line = FundingLine.first
      @response = request(resource(@funding_line), :method => "PUT", 
        :params => { :funding_line => {:id => @funding_line.id} })
    end
  
    it "redirect to the funding_line show action" do
      @response.should redirect_to(resource(@funding_line))
    end
  end
  
end

