require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a ledger_entry exists" do
  LedgerEntry.all.destroy!
  request(resource(:ledger_entries), :method => "POST", 
    :params => { :ledger_entry => { :id => nil }})
end

describe "resource(:ledger_entries)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:ledger_entries))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of ledger_entries" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a ledger_entry exists" do
    before(:each) do
      @response = request(resource(:ledger_entries))
    end
    
    it "has a list of ledger_entries" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      LedgerEntry.all.destroy!
      @response = request(resource(:ledger_entries), :method => "POST", 
        :params => { :ledger_entry => { :id => nil }})
    end
    
    it "redirects to resource(:ledger_entries)" do
      @response.should redirect_to(resource(LedgerEntry.first), :message => {:notice => "ledger_entry was successfully created"})
    end
    
  end
end

describe "resource(@ledger_entry)" do 
  describe "a successful DELETE", :given => "a ledger_entry exists" do
     before(:each) do
       @response = request(resource(LedgerEntry.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:ledger_entries))
     end

   end
end

describe "resource(:ledger_entries, :new)" do
  before(:each) do
    @response = request(resource(:ledger_entries, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@ledger_entry, :edit)", :given => "a ledger_entry exists" do
  before(:each) do
    @response = request(resource(LedgerEntry.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@ledger_entry)", :given => "a ledger_entry exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(LedgerEntry.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @ledger_entry = LedgerEntry.first
      @response = request(resource(@ledger_entry), :method => "PUT", 
        :params => { :ledger_entry => {:id => @ledger_entry.id} })
    end
  
    it "redirect to the ledger_entry show action" do
      @response.should redirect_to(resource(@ledger_entry))
    end
  end
  
end

