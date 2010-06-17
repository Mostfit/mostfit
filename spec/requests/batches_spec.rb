require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a batch exists" do
  Batch.all.destroy!
  request(resource(:batches), :method => "POST", 
    :params => { :batch => { :id => nil }})
end

describe "resource(:batches)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:batches))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of batches" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a batch exists" do
    before(:each) do
      @response = request(resource(:batches))
    end
    
    it "has a list of batches" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Batch.all.destroy!
      @response = request(resource(:batches), :method => "POST", 
        :params => { :batch => { :id => nil }})
    end
    
    it "redirects to resource(:batches)" do
      @response.should redirect_to(resource(Batch.first), :message => {:notice => "batch was successfully created"})
    end
    
  end
end

describe "resource(@batch)" do 
  describe "a successful DELETE", :given => "a batch exists" do
     before(:each) do
       @response = request(resource(Batch.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:batches))
     end

   end
end

describe "resource(:batches, :new)" do
  before(:each) do
    @response = request(resource(:batches, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@batch, :edit)", :given => "a batch exists" do
  before(:each) do
    @response = request(resource(Batch.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@batch)", :given => "a batch exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Batch.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @batch = Batch.first
      @response = request(resource(@batch), :method => "PUT", 
        :params => { :batch => {:id => @batch.id} })
    end
  
    it "redirect to the batch show action" do
      @response.should redirect_to(resource(@batch))
    end
  end
  
end

