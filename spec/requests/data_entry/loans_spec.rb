require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper.rb')

given "a loan exist" do
  Loan.all.destroy!
end

given "an admin user exist" do
  User.all.destroy!
  load_fixtures :users
  response = request url(:perform_login), :method => "PUT", :params => {:login => 'admin', :password => 'password'}
  response.should redirect
end

describe "/data_entry/loans", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/data_entry/loans/new")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end

describe "/data_entry/loans/edit", :given => "an admin user exist" do
  describe "PUT" do
    before(:each) do
      @response = request("/data_entry/loans/edit")
    end

    it "responds successsfully" do
      @response.should be_successful
    end
  end
end

describe "/data_entry/loans/approve", :given => "an admin user exist" do
  describe "PUT" do
    before(:each) do
      @response = request("/loans/approve")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end

describe "/loans/disburse", :given =>"an admin user exist" do
  describe "PUT" do
    before(:each) do
      @response= request("/loans/disburse")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end

describe "/loans/write_off_suggested", :given =>"an admin user exist" do
  describe "PUT" do
    before(:each) do
      @response= request("/loans/write_off_suggested")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end

describe "/reports/ProjectedReport", :given =>"an admin user exist" do
  describe "PUT" do
    before(:each) do
      @response= request("/reports/ProjectedReport")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end

describe "/data_entry/loans/staff_disbursement_sheet", :given =>"an admin user exist" do
  describe "PUT" do
    before(:each) do
      @response= request("/data_entry/loans/staff_disbursement_sheet")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end
