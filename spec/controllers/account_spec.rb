require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')

describe Accounts, "Check accounts" do
  before do
    load_fixtures :users, :account_type, :staff_members
  end

  def create(branch)
    @branch = Branch.new(branch)
    if @branch.save
      redirect(params[:return]||resource(:branches), :message => {:notice => "Branch #{@branch.name}' successfully created"})
      else
        message[:error] = "Branch failed to be created"
        render :new
      end
  end
 
  it "create a new account" do
  
    response = request url(:perform_login), :method => "PUT", :params => {:login => 'admin', :password => 'password'}
    response.should redirect
    request("/accounts/new").should be_successful
    
    @branch       = Branch.first
    @account_type = AccountType.first
    @staff_member = StaffMember.first
    
    params = {}
    
    params[:account] = 
      
      {
      "name"=>"Grey", "gl_code"=>"GHD2", "branch_id"=> @branch.id,      "account_type_id"=> @account_type.id, "parent_id"=>"1", 
      "opening_balance_on_date"=>"21 September, 2010", 
      "opening_balance"=>"0"
    }
        
    response = request resource(:accounts), :method => "POST", :params => params

    response.should redirect
    Account.first(:name => "Test1").should_not nil
    
  end

  it "edit a new account" do
    response = request url(:perform_login), :method => "PUT", :params => {:login => 'admin', :password => 'password'}
    response.should redirect
    @account = Account.first
    request(url(:accounts)).should be_successful
    params = {}
    hash                = @account.attributes
    hash[:name]         = @account.name+"_modified"
    params[:id]         = @account.id
    params[:account]    = hash
    response = request resource(:accounts), :method => "POST", :params => params
  #  response.should redirect
    
    new_name = Account.get(@account.id).name
    new_name.should_not equal(@account.name)
 end
end

    


