require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a report exists" do
  Report.all.destroy!
  request(resource(:reports), :method => "POST", 
    :params => { :report => { :id => nil }})
end

describe "resource(:reports)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:reports))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of reports" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a report exists" do
    before(:each) do
      @response = request(resource(:reports))
    end
    
    it "has a list of reports" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Report.all.destroy!
      @response = request(resource(:reports), :method => "POST", 
        :params => { :report => { :id => nil }})
    end
    
    it "redirects to resource(:reports)" do
      @response.should redirect_to(resource(Report.first), :message => {:notice => "report was successfully created"})
    end
    
  end
end

describe "resource(@report)" do 
  describe "a successful DELETE", :given => "a report exists" do
     before(:each) do
       @response = request(resource(Report.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:reports))
     end

   end
end

describe "resource(:reports, :new)" do
  before(:each) do
    @response = request(resource(:reports, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@report, :edit)", :given => "a report exists" do
  before(:each) do
    @response = request(resource(Report.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@report)", :given => "a report exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Report.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @report = Report.first
      @response = request(resource(@report), :method => "PUT", 
        :params => { :report => {:id => @report.id} })
    end
  
    it "redirect to the report show action" do
      @response.should redirect_to(resource(@report))
    end
  end
  
end

