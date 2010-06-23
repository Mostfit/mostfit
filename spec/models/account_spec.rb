require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Account do
  before(:all) do
    AccountType.all.destroy!
    @account_type = AccountType.new(:name => "Assets", :code => "AST")
    @account_type.save
    @account_type.error
    @account_type.should be_valid
  end

  before(:each) do
    Account.all.destroy!
    @account = Account.new(:name => "Cash Account", :gl_code => "CA1001")
    @account.account_type = @account_type
    @account.save
    @account.error
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
    @acc = Account.new(:name => "Income Account", :gl_code => "IA1002", :account_type => @account_type)
    @acc.save
    @acc.error
    @acc.should be_valid
    
    @account.account = @acc
    @account.should be_valid
  end
end
