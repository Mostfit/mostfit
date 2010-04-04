require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a document_type exists" do
  DocumentType.all.destroy!
  request(resource(:document_types), :method => "POST", 
    :params => { :document_type => { :id => nil }})
end

describe "resource(:document_types)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:document_types))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of document_types" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a document_type exists" do
    before(:each) do
      @response = request(resource(:document_types))
    end
    
    it "has a list of document_types" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      DocumentType.all.destroy!
      @response = request(resource(:document_types), :method => "POST", 
        :params => { :document_type => { :id => nil }})
    end
    
    it "redirects to resource(:document_types)" do
      @response.should redirect_to(resource(DocumentType.first), :message => {:notice => "document_type was successfully created"})
    end
    
  end
end

describe "resource(@document_type)" do 
  describe "a successful DELETE", :given => "a document_type exists" do
     before(:each) do
       @response = request(resource(DocumentType.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:document_types))
     end

   end
end

describe "resource(:document_types, :new)" do
  before(:each) do
    @response = request(resource(:document_types, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@document_type, :edit)", :given => "a document_type exists" do
  before(:each) do
    @response = request(resource(DocumentType.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@document_type)", :given => "a document_type exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(DocumentType.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @document_type = DocumentType.first
      @response = request(resource(@document_type), :method => "PUT", 
        :params => { :document_type => {:id => @document_type.id} })
    end
  
    it "redirect to the document_type show action" do
      @response.should redirect_to(resource(@document_type))
    end
  end
  
end

