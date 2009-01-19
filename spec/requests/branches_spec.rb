require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a branch exists" do
  Branch.all.destroy!
  request(resource(:branches), :method => "POST", 
    :params => { :branch => { :id => nil }})
end

describe "resource(:branches)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:branches))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of branches" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a branch exists" do
    before(:each) do
      @response = request(resource(:branches))
    end
    
    it "has a list of branches" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Branch.all.destroy!
      @response = request(resource(:branches), :method => "POST", 
        :params => { :branch => { :id => nil }})
    end
    
    it "redirects to resource(:branches)" do
      @response.should redirect_to(resource(Branch.first), :message => {:notice => "branch was successfully created"})
    end
    
  end
end

describe "resource(@branch)" do 
  describe "a successful DELETE", :given => "a branch exists" do
     before(:each) do
       @response = request(resource(Branch.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:branches))
     end

   end
end

describe "resource(:branches, :new)" do
  before(:each) do
    @response = request(resource(:branches, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@branch, :edit)", :given => "a branch exists" do
  before(:each) do
    @response = request(resource(Branch.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@branch)", :given => "a branch exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Branch.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @branch = Branch.first
      @response = request(resource(@branch), :method => "PUT", 
        :params => { :branch => {:id => @branch.id} })
    end
  
    it "redirect to the article show action" do
      @response.should redirect_to(resource(@branch))
    end
  end
  
end

