require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')

describe Accounts, "Check accounts" do
  before do
    load_fixtures :users, :account_type, :staff_members,:branches
  end

 
  it "create a new account" do
    debugger
    response = request url(:perform_login), :method => "PUT", :params => {:login => 'admin', :password => 'password'}
    response.should redirect
    request("/accounts/new").should be_successful
    @branch       = Branch.first
    @account_type = AccountType.first
    @staff_member = StaffMember.first
    params = {}
    
    params[:account] = {:account_type => @account_type, :branch => @branch, :name => "Test1", :gl_code => "ABC1", :opening_balance => "0", :opening_balance_on_date => {"month" => "9", "day" => "10", "year" => "2010"}}
  
    response = request resource(:accounts), :method => "POST", :params => params

   #response.should redirect
    Account.first(:name => "Test1").should_not nil
    
  end

 #  it "edit a new account" do
 #    response = request url(:perform_login), :method => "PUT", :params => {:login => 'admin', :password => 'password'}
 #    response.should redirect
 #    @account = Account.first
 #    request(url(:accounts)).should be_successful
 #    params = {}
 #    hash                = @account.attributes
 #    hash[:name]         = @account.name+"_modified"
 #    params[:id]         = @account.id
 #    params[:account]    = hash
 #    response = request resource(@account), :method => "POST", :params => params
 #  #  response.should redirect
 #    new_name = Account.get(@account.id).name
 #    new_name.should_not equal(@account.name)
 # end
end

    


