require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper.rb')

given "payments exists" do
  Payment.all.destroy!
end

given "an admin user exist" do
  User.all.destroy!
  load_fixtures :users
  response = request url(:perform_login), :method => "PUT", :params => {:login => 'admin', :password => 'password'}
  response.should redirect
end

describe "/data_entry/payments/record", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/data_entry/payments/record")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end

describe "/data_entry/payments/by_center", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/data_entry/payments/by_center")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end

describe "/data_entry/payments/by_staff_member", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/data_entry/payments/by_staff_member")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end

describe "/data_entry/payments/delete", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/data_entry/payments/delete")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end

describe "/data_entry/payments/staff_collection_sheet", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/data_entry/payments/staff_collection_sheet")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end

describe "/reports/DailyReport", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/reports/DailyReport")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end

describe "/reports/TransactionLedger", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/reports/TransactionLedger")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end
