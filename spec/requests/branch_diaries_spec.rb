require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a branch_diary exists" do
  BranchDiary.all.destroy!
  request(resource(:branch_diaries), :method => "POST", 
    :params => { :branch_diary => { :id => nil }})
end

describe "resource(:branch_diaries)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:branch_diaries))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of branch_diaries" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a branch_diary exists" do
    before(:each) do
      @response = request(resource(:branch_diaries))
    end
    
    it "has a list of branch_diaries" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      BranchDiary.all.destroy!
      @response = request(resource(:branch_diaries), :method => "POST", 
        :params => { :branch_diary => { :id => nil }})
    end
    
    it "redirects to resource(:branch_diaries)" do
      @response.should redirect_to(resource(BranchDiary.first), :message => {:notice => "branch_diary was successfully created"})
    end
    
  end
end

describe "resource(@branch_diary)" do 
  describe "a successful DELETE", :given => "a branch_diary exists" do
     before(:each) do
       @response = request(resource(BranchDiary.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:branch_diaries))
     end

   end
end

describe "resource(:branch_diaries, :new)" do
  before(:each) do
    @response = request(resource(:branch_diaries, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@branch_diary, :edit)", :given => "a branch_diary exists" do
  before(:each) do
    @response = request(resource(BranchDiary.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@branch_diary)", :given => "a branch_diary exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(BranchDiary.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @branch_diary = BranchDiary.first
      @response = request(resource(@branch_diary), :method => "PUT", 
        :params => { :branch_diary => {:id => @branch_diary.id} })
    end
  
    it "redirect to the branch_diary show action" do
      @response.should redirect_to(resource(@branch_diary))
    end
  end
  
end

