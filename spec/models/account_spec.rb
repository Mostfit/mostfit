require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Account do
  before(:all) do
    AccountType.all.destroy!
    @account_type = AccountType.new(:name => "Assets", :code => "AST")
    @account_type.save
    @account_type.errors
    @account_type.should be_valid

    @manager = StaffMember.new(:name => "Mrs. M.A. Nerger")
    @manager.save
    @manager.errors
    @manager.should be_valid

    @branch = Branch.new(:name => "Kerela branch")
    @branch.manager = @manager
    @branch.code = "ker"
    @branch.save
    @branch.errors
    @branch.should be_valid
  end

  before(:each) do
    Account.all.destroy!
    @account = Account.new(:name => "Cash Account", :gl_code => "CA1001", :opening_balance_on_date => Date.today)
    @account.account_type = @account_type
    @account.save
    @account.errors
    @account.should be_valid
  end
  
  it "should not be valid without a name" do
    @account.name = nil
    @account.should_not be_valid
  end

  it "should not be valid without a gl_code" do
    @account.gl_code = nil
    @account.should_not be_valid
  end

  it "should not be valid without a account_type" do
    @account.account_type_id = nil
    @account.should_not be_valid
  end
  
  it "should not be valid with a name shorter than 3 characters" do
    @account.name = "ac"
    @account.should_not be_valid
  end

  it "should not be valid with a gl_code shorter than 3 characters" do
    @account.gl_code = "ia"
    @account.should_not be_valid
  end

  it "should be able to 'have' account" do
    @acc = Account.new(:name => "Income Account", :gl_code => "IA1002", :account_type => @account_type, :opening_balance_on_date => Date.today)
    @acc.save
    @acc.errors
    @acc.should be_valid
    @account.account = @acc
    @account.should be_valid
  end

  it "should be valid with or without branch" do
    @account.branch = @branch
    @account.should be_valid
    @account.branch = nil
    @account.should be_valid
  end
end
