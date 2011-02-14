require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a account exists" do
  Account.all.destroy!
end

given "an admin user exist" do
  load_fixtures :users
  response = request url(:perform_login), :method => "PUT", :params => { :login => "admin", :password => "password"}
  response.should redirect
end

given "an account and admin user exist" do
  load_fixtures :users, :staff_members
  response = request url(:perform_login), :method => "PUT", :params => { :login => "admin", :password => "password"}
  response.should redirect
end

describe "resource(:accounts)", :given => "an admin user exist" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:accounts))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of accounts" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a account exists" do
    before(:each) do
      @response = request(resource(:accounts))
    end
    
    it "has a list of accounts" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Account.all.destroy!
      @response = request(resource(:accounts), :method => "POST", :params => { :account => { :name => "Savings", :account_type_id => 1, :gl_code => "ABC" }})
    end
    
    it "redirects to resource(:accounts)" do
      @response.should redirect_to(resource(:accounts), :message => {:notice => "account was successfully created"})
    end
  end
end

describe "resource(@account)", :given => "an admin user exist" do 
  describe "a successful DELETE", :given => "a account exists" do
    before(:each) do
      pending
      @response = request(resource(Account.first), :method => "DELETE")
    end

    it "should redirect to the index action" do
      @response.should redirect_to(resource(:accounts))
    end
  end
end

describe "resource(:accounts, :new)", :given => "an admin user exist" do
  before(:each) do
    @response = request(resource(:accounts, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@account, :edit)", :given => "an admin user exist" do
  before(:each) do
    pending
    @response = request(resource(Account.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@account)", :given => "an account and admin user exist" do
  
  describe "GET" do
    before(:each) do
      pending
      @response = request(resource(Account.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @account = Account.first
      pending
      @response = request(resource(@account), :method => "PUT", :params => { :account => {:id => @account.id} })
    end
  
    it "redirect to the account show action" do
      @response.should redirect_to(resource(@account))
    end
  end
end

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
  end
end

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
  end
end

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
  end
end

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
  end
end

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
  end
end
