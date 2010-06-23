require File.join( File.dirname(__FILE__), '..', "spec_helper" )
describe AccountType do
  
  before (:all) do
    @user = User.new(:login => 'admin', :password => 'password', :password_confirmation => 'password', 
                     :role => :admin)
    @user.save
    @user.should be_valid
  end
  
  before (:each) do
    AccountType.all.destroy!
    @account_type = AccountType.new(:name => 'Assets', :code => '10000')
    @account_type.save
    @account_type.errors.each {|e| p e}
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
     name = "cash"
    @account = Account.new(:name => name,:gl_code => "123aq")
    @account.account_type = @account_type
    @account.parent_id = @account
    @account.opening_balance = "0"
    @account.save 
    @account.should be_valid
    
    @account_type.should be_valid
    @account_type.accounts.first.name.should eql(name)
 
    petty_cash = Account.new(:name => 'petty_cash 1',:gl_code => 'qw123')
    petty_cash.account_type = @account_type
    petty_cash.should be_valid
    
    @account_type.accounts << petty_cash
    @account_type.should be_valid
    @account_type.accounts.size.should eql(2)
  end

end
