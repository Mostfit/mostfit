require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a posting exists" do
  Posting.all.destroy!
  request(resource(:postings), :method => "POST", 
    :params => { :posting => { :id => nil }})
end

describe "resource(:postings)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:postings))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of postings" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a posting exists" do
    before(:each) do
      @response = request(resource(:postings))
    end
    
    it "has a list of postings" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Posting.all.destroy!
      @response = request(resource(:postings), :method => "POST", 
        :params => { :posting => { :id => nil }})
    end
    
    it "redirects to resource(:postings)" do
      @response.should redirect_to(resource(Posting.first), :message => {:notice => "posting was successfully created"})
    end
    
  end
end

describe "resource(@posting)" do 
  describe "a successful DELETE", :given => "a posting exists" do
     before(:each) do
       @response = request(resource(Posting.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:postings))
     end

   end
end

describe "resource(:postings, :new)" do
  before(:each) do
    @response = request(resource(:postings, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@posting, :edit)", :given => "a posting exists" do
  before(:each) do
    @response = request(resource(Posting.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@posting)", :given => "a posting exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Posting.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @posting = Posting.first
      @response = request(resource(@posting), :method => "PUT", 
        :params => { :posting => {:id => @posting.id} })
    end
  
    it "redirect to the posting show action" do
      @response.should redirect_to(resource(@posting))
    end
  end
  
end

