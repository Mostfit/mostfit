require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "an admin user" do
  load_fixtures :users if User.all.blank?
  response = request url(:perform_login), :method => "PUT", :params => { :login => 'admin', :password => 'password' }
  response.should redirect
end

describe "/browse", :given => "an admin user" do
  describe "GET" do
    before(:each) do
      @response = request("/browse")
    end

    it "responds successfully" do
      @response.should be_successful
    end

    it "should have branches" do
      pending
      @response.should have_xpath("//ul/li")
    end

    it "should have staff_members" do
      pending
      @response.should have_xpath("//ul/li[2]")
    end

    it "should have centers_paying_today" do
      pending
      @response.should have_xpath("//ul/li[3]")
    end

    it "should have verifications" do
      pending
      @response.should have_xpath("//ul/li[4]")
    end
    
    it "should have documents" do
      pending
      @response.should have_xpath("//ul/li[5]")
    end
  end
end
