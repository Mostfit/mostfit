require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a repayment_style exists" do
  RepaymentStyle.all.destroy!
  request(resource(:repayment_styles), :method => "POST", 
    :params => { :repayment_style => { :id => nil }})
end

describe "resource(:repayment_styles)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:repayment_styles))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of repayment_styles" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a repayment_style exists" do
    before(:each) do
      @response = request(resource(:repayment_styles))
    end
    
    it "has a list of repayment_styles" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      RepaymentStyle.all.destroy!
      @response = request(resource(:repayment_styles), :method => "POST", 
        :params => { :repayment_style => { :id => nil }})
    end
    
    it "redirects to resource(:repayment_styles)" do
      @response.should redirect_to(resource(RepaymentStyle.first), :message => {:notice => "repayment_style was successfully created"})
    end
    
  end
end

describe "resource(@repayment_style)" do 
  describe "a successful DELETE", :given => "a repayment_style exists" do
     before(:each) do
       @response = request(resource(RepaymentStyle.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:repayment_styles))
     end

   end
end

describe "resource(:repayment_styles, :new)" do
  before(:each) do
    @response = request(resource(:repayment_styles, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@repayment_style, :edit)", :given => "a repayment_style exists" do
  before(:each) do
    @response = request(resource(RepaymentStyle.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@repayment_style)", :given => "a repayment_style exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(RepaymentStyle.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @repayment_style = RepaymentStyle.first
      @response = request(resource(@repayment_style), :method => "PUT", 
        :params => { :repayment_style => {:id => @repayment_style.id} })
    end
  
    it "redirect to the repayment_style show action" do
      @response.should redirect_to(resource(@repayment_style))
    end
  end
  
end

