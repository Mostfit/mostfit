require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a report_format exists" do
  ReportFormat.all.destroy!
  request(resource(:report_formats), :method => "POST", 
    :params => { :report_format => { :id => nil }})
end

describe "resource(:report_formats)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:report_formats))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of report_formats" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a report_format exists" do
    before(:each) do
      @response = request(resource(:report_formats))
    end
    
    it "has a list of report_formats" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      ReportFormat.all.destroy!
      @response = request(resource(:report_formats), :method => "POST", 
        :params => { :report_format => { :id => nil }})
    end
    
    it "redirects to resource(:report_formats)" do
      @response.should redirect_to(resource(ReportFormat.first), :message => {:notice => "report_format was successfully created"})
    end
    
  end
end

describe "resource(@report_format)" do 
  describe "a successful DELETE", :given => "a report_format exists" do
     before(:each) do
       @response = request(resource(ReportFormat.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:report_formats))
     end

   end
end

describe "resource(:report_formats, :new)" do
  before(:each) do
    @response = request(resource(:report_formats, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@report_format, :edit)", :given => "a report_format exists" do
  before(:each) do
    @response = request(resource(ReportFormat.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@report_format)", :given => "a report_format exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(ReportFormat.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @report_format = ReportFormat.first
      @response = request(resource(@report_format), :method => "PUT", 
        :params => { :report_format => {:id => @report_format.id} })
    end
  
    it "redirect to the report_format show action" do
      @response.should redirect_to(resource(@report_format))
    end
  end
  
end

