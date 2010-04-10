require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a audit_item exists" do
  AuditItem.all.destroy!
  request(resource(:audit_items), :method => "POST", 
    :params => { :audit_item => { :id => nil }})
end

describe "resource(:audit_items)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:audit_items))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of audit_items" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a audit_item exists" do
    before(:each) do
      @response = request(resource(:audit_items))
    end
    
    it "has a list of audit_items" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      AuditItem.all.destroy!
      @response = request(resource(:audit_items), :method => "POST", 
        :params => { :audit_item => { :id => nil }})
    end
    
    it "redirects to resource(:audit_items)" do
      @response.should redirect_to(resource(AuditItem.first), :message => {:notice => "audit_item was successfully created"})
    end
    
  end
end

describe "resource(@audit_item)" do 
  describe "a successful DELETE", :given => "a audit_item exists" do
     before(:each) do
       @response = request(resource(AuditItem.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:audit_items))
     end

   end
end

describe "resource(:audit_items, :new)" do
  before(:each) do
    @response = request(resource(:audit_items, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@audit_item, :edit)", :given => "a audit_item exists" do
  before(:each) do
    @response = request(resource(AuditItem.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@audit_item)", :given => "a audit_item exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(AuditItem.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @audit_item = AuditItem.first
      @response = request(resource(@audit_item), :method => "PUT", 
        :params => { :audit_item => {:id => @audit_item.id} })
    end
  
    it "redirect to the audit_item show action" do
      @response.should redirect_to(resource(@audit_item))
    end
  end
  
end

