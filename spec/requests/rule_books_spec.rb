require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a rule_book exists" do
  RuleBook.all.destroy!
  request(resource(:rule_books), :method => "POST", 
    :params => { :rule_book => { :id => nil }})
end

describe "resource(:rule_books)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:rule_books))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of rule_books" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a rule_book exists" do
    before(:each) do
      @response = request(resource(:rule_books))
    end
    
    it "has a list of rule_books" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      RuleBook.all.destroy!
      @response = request(resource(:rule_books), :method => "POST", 
        :params => { :rule_book => { :id => nil }})
    end
    
    it "redirects to resource(:rule_books)" do
      @response.should redirect_to(resource(RuleBook.first), :message => {:notice => "rule_book was successfully created"})
    end
    
  end
end

describe "resource(@rule_book)" do 
  describe "a successful DELETE", :given => "a rule_book exists" do
     before(:each) do
       @response = request(resource(RuleBook.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:rule_books))
     end

   end
end

describe "resource(:rule_books, :new)" do
  before(:each) do
    @response = request(resource(:rule_books, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@rule_book, :edit)", :given => "a rule_book exists" do
  before(:each) do
    @response = request(resource(RuleBook.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@rule_book)", :given => "a rule_book exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(RuleBook.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @rule_book = RuleBook.first
      @response = request(resource(@rule_book), :method => "PUT", 
        :params => { :rule_book => {:id => @rule_book.id} })
    end
  
    it "redirect to the rule_book show action" do
      @response.should redirect_to(resource(@rule_book))
    end
  end
  
end

