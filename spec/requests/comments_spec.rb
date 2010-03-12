require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a comment exists" do
  Comment.all.destroy!
  request(resource(:comments), :method => "POST", 
    :params => { :comment => { :id => nil }})
end

describe "resource(:comments)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:comments))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of comments" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a comment exists" do
    before(:each) do
      @response = request(resource(:comments))
    end
    
    it "has a list of comments" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Comment.all.destroy!
      @response = request(resource(:comments), :method => "POST", 
        :params => { :comment => { :id => nil }})
    end
    
    it "redirects to resource(:comments)" do
      @response.should redirect_to(resource(Comment.first), :message => {:notice => "comment was successfully created"})
    end
    
  end
end

describe "resource(@comment)" do 
  describe "a successful DELETE", :given => "a comment exists" do
     before(:each) do
       @response = request(resource(Comment.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:comments))
     end

   end
end

describe "resource(:comments, :new)" do
  before(:each) do
    @response = request(resource(:comments, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@comment, :edit)", :given => "a comment exists" do
  before(:each) do
    @response = request(resource(Comment.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@comment)", :given => "a comment exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Comment.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @comment = Comment.first
      @response = request(resource(@comment), :method => "PUT", 
        :params => { :comment => {:id => @comment.id} })
    end
  
    it "redirect to the comment show action" do
      @response.should redirect_to(resource(@comment))
    end
  end
  
end

