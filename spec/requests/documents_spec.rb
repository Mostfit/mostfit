require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a document exists" do
  Document.all.destroy!
  request(resource(:documents), :method => "POST", 
    :params => { :document => { :id => nil }})
end

describe "resource(:documents)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:documents))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of documents" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a document exists" do
    before(:each) do
      @response = request(resource(:documents))
    end
    
    it "has a list of documents" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Document.all.destroy!
      @response = request(resource(:documents), :method => "POST", 
        :params => { :document => { :id => nil }})
    end
    
    it "redirects to resource(:documents)" do
      @response.should redirect_to(resource(Document.first), :message => {:notice => "document was successfully created"})
    end
    
  end
end

describe "resource(@document)" do 
  describe "a successful DELETE", :given => "a document exists" do
     before(:each) do
       @response = request(resource(Document.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:documents))
     end

   end
end

describe "resource(:documents, :new)" do
  before(:each) do
    @response = request(resource(:documents, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@document, :edit)", :given => "a document exists" do
  before(:each) do
    @response = request(resource(Document.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@document)", :given => "a document exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Document.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @document = Document.first
      @response = request(resource(@document), :method => "PUT", 
        :params => { :document => {:id => @document.id} })
    end
  
    it "redirect to the document show action" do
      @response.should redirect_to(resource(@document))
    end
  end
  
end

