require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a journal exists" do
  Journal.all.destroy!
  request(resource(:journals), :method => "POST", 
    :params => { :journal => { :id => nil }})
end

describe "resource(:journals)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:journals))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of journals" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a journal exists" do
    before(:each) do
      @response = request(resource(:journals))
    end
    
    it "has a list of journals" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Journal.all.destroy!
      @response = request(resource(:journals), :method => "POST", 
        :params => { :journal => { :id => nil }})
    end
    
    it "redirects to resource(:journals)" do
      @response.should redirect_to(resource(Journal.first), :message => {:notice => "journal was successfully created"})
    end
    
  end
end

describe "resource(@journal)" do 
  describe "a successful DELETE", :given => "a journal exists" do
     before(:each) do
       @response = request(resource(Journal.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:journals))
     end

   end
end

describe "resource(:journals, :new)" do
  before(:each) do
    @response = request(resource(:journals, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@journal, :edit)", :given => "a journal exists" do
  before(:each) do
    @response = request(resource(Journal.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@journal)", :given => "a journal exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Journal.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @journal = Journal.first
      @response = request(resource(@journal), :method => "PUT", 
        :params => { :journal => {:id => @journal.id} })
    end
  
    it "redirect to the journal show action" do
      @response.should redirect_to(resource(@journal))
    end
  end
  
end

