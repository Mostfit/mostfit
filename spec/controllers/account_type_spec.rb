require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')

describe AccountTypes, "Check types" do
  before(:all) do
    load_fixtures :users
  end

  it "create a new account type" do
    response = request url(:perform_login), :method => "PUT", :params => {:login => 'admin', :password => 'password'}
    response.should redirect
    request("/account_types").should be_successful
    params = {}
    params[:account_type] = {:name => "Asset", :code => "PUC1"}
    response = request resource(:account_types), :method => "POST", :params => params
    response.should redirect
    AccountType.all(:name => "asset").count.should == 1
  end

  it "edit a account type" do
    response = request url(:perform_login), :method => "PUT", :params => {:login => 'admin', :password => 'password'}
    response.should redirect    

    request(url(:account_types)).should be_successful
    params = {}

    @account_type = AccountType.first
    hash                   = @account_type.attributes
    hash[:name]            = #{@account_type.name} + "_modified"
    params[:id]            = @account_type.id
    params[:account_type]  = hash
    response = request resource(@account_type), :method => "POST", :params => params
    new_name = AccountType.get(@account_type.id).name
    new_name.should_not equal(@account_type.name)
  end
end
