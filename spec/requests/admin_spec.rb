require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "an admin user" do
  load_fixtures :users
  response = request url(:perform_login), :method => "PUT", :params => { :login => 'admin', :password => 'password' }
  response.should redirect
end

describe "/admin", :given => "an admin user" do
  describe "GET" do
    before(:each) do
      @response = request("/admin")
    end
    
    it "responds successfully" do
      @response.should be_successful
    end
    
    #Manage organization profile and calendar
    it "should have edit" do    
      pending
      @response.should have_xpath("//ul/li")
    end
    
    it "should have holidays" do
      pending
      @response.should have_xpath("//ul/li[2]")
    end
    
    #Manage geographical locations
    it "should have regions" do
      pending
      @response.should have_xpath("//ul[2]/li")
    end
    
    it "should have areas" do
      pending
      @response.should have_xpath("//ul[2]/li[2]")
    end
    
    #Manage staff, users, and roles
    it "should have staff members" do
      pending
      @response.should have_xpath("//ul[3]/li")
    end
    
    it "should have users and roles" do
      pending
      @response.should have_xpath("//ul[3]/li[2]")
    end
    
    #Manage financial products, funds, rules, and accounting
    it "should have funders" do
      pending
      @response.should have_xpath("//ul[4]/li")
    end

    it "should have rules" do
      pending
      @response.should have_xpath("//ul[4]/li[2]")
    end

    it "should have targets" do
      pending
      @response.should have_xpath("//ul[4]/li[3]")
    end

    it "should have fees" do
      pending
      @response.should have_xpath("//ul[4]/li[4]")
    end
    
    it "should have loan products" do
      pending
      @response.should have_xpath("//ul[4]/li[5]")
    end

    it "should have insurance companies" do
      pending
      @response.should have_xpath("//ul[4]/li[6]")
    end
    
    it "should have accounts" do
      pending
      @response.should have_xpath("//ul[4]/li[7]")
    end
    
    #Manage commonly-used lists (masters)
    it "should have client types" do
      pending
      @response.should have_xpath("//ul[5]/li")
    end
    
    it "should have occupations" do
      pending
      @response.should have_xpath("//ul[5]/li[2]")
    end
    
    it "should have loan utilizations" do
      pending
      @response.should have_xpath("//ul[5]/li[3]")
    end
    
    it "should have document types" do
      pending
      @response.should have_xpath("//ul[5]/li[4]")
    end

    it "should have stock list" do
      pending
      @response.should have_xpath("//ul[5]/li[5]")
    end
    
    #Assign targets, perform audits
    it "should have targets" do
      pending
      @response.should have_xpath("//ul[6]/li")
    end
    
    it "should have audit items" do
      pending
      @response.should have_xpath("//ul[6]/li[2]")
    end

    it "should have history log" do
      pending
      @response.should have_xpath("//ul[6]/li[3]")
    end
    
    #Data
    it "should have upload" do
      pending
      @response.should have_xpath("//ul[7]/li")
    end
    
    it "should have download" do
      pending
      @response.should have_xpath("//ul[7]/li[2]")
    end
  end
end
