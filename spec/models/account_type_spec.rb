require File.join( File.dirname(__FILE__), '..', "spec_helper" )
describe AccountType do
  
  before (:each) do
    AccountType.all.destroy!
    @account_type = Factory(:account_type, :name => 'Assets', :code => '10000')
  end

  it "should be valid with default attributes" do
    @account_type.should be_valid
  end

  it "should not valid without name" do
    @account_type.name = nil
    @account_type.should_not be_valid
  end 

  it "should not valid without code" do
    @account_type.code = nil
    @account_type.should_not be_valid 
  end 

  it "name should not less than 3 charactor" do
    @account_type.name = "dx"
    @account_type.should_not be_valid
  end
  
  it "code should not less than 3 charactor" do
    @account_type.code = "A1"
    @account_type.should_not be_valid 
  end
  
  it "should be able to have accounts" do
    account_name = 'cash'

    account = Factory( :account, :name => account_name, :gl_code => "123aq", :opening_balance => 0, :account_type => @account_type )
    account.should be_valid

    @account_type.should be_valid
    @account_type.accounts.first.name.should eql(account_name)
 
    account2 = Factory( :account, :name => 'petty_cash 1',:gl_code => 'qw123', :account_type => @account_type )
    account2.should be_valid
    
    @account_type.should be_valid
    @account_type.accounts.size.should eql(2)
  end

end
