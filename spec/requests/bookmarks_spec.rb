require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a bookmark exists" do
  Bookmark.all.destroy!
  request(resource(:bookmarks), :method => "POST", 
    :params => { :bookmark => { :id => nil }})
end

describe "resource(:bookmarks)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:bookmarks))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of bookmarks" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a bookmark exists" do
    before(:each) do
      @response = request(resource(:bookmarks))
    end
    
    it "has a list of bookmarks" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Bookmark.all.destroy!
      @response = request(resource(:bookmarks), :method => "POST", 
        :params => { :bookmark => { :id => nil }})
    end
    
    it "redirects to resource(:bookmarks)" do
      @response.should redirect_to(resource(Bookmark.first), :message => {:notice => "bookmark was successfully created"})
    end
    
  end
end

describe "resource(@bookmark)" do 
  describe "a successful DELETE", :given => "a bookmark exists" do
     before(:each) do
       @response = request(resource(Bookmark.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:bookmarks))
     end

   end
end

describe "resource(:bookmarks, :new)" do
  before(:each) do
    @response = request(resource(:bookmarks, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@bookmark, :edit)", :given => "a bookmark exists" do
  before(:each) do
    @response = request(resource(Bookmark.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@bookmark)", :given => "a bookmark exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Bookmark.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @bookmark = Bookmark.first
      @response = request(resource(@bookmark), :method => "PUT", 
        :params => { :bookmark => {:id => @bookmark.id} })
    end
  
    it "redirect to the bookmark show action" do
      @response.should redirect_to(resource(@bookmark))
    end
  end
  
end

