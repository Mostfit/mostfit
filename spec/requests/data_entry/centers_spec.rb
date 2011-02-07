require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper.rb')

given "a center exists" do
  Center.all.destroy!
end

given "an admin user exist" do
  User.all.destroy!
  load_fixtures :users
  response = request url(:perform_login), :method => "PUT", :params => {:login => 'admin', :password => 'password'}
  response.should redirect
end

describe "/data_entry/centers", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      pending
      @response = request("/centers/new")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end

describe "/data_entry/centers/edit", :given => "an admin user exist" do
  describe "PUT" do
    before(:each) do
      @response = request("/data_entry/centers/edit")
    end

    it "responds successsfully" do
      @response.should be_successful
    end
  end
end

describe "/data_entry/loans/make_loan_utilization", :given => "an admin user exist" do
  describe "PUT" do
    before(:each) do
      @response = request("/data_entry/loans/make_loan_utilization")
    end

    it "responds successsfully" do
      @response.should be_successful
    end
  end
end
