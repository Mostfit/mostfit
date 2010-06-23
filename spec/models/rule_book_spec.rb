require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe RuleBook do
 
  before (:all) do
#    @user = User.new(:login => 'admin', :password => 'password', :password_confirmation => 'password',
#                     :role => :admin)
#    @user.save
#    @user.should be_valid
    
    @account_type = AccountType.new(:name => 'Assets',:code => '20000')
    @account_type.save
    @account_type.should be_valid 
    
    @account = Account.new(:name => 'petty cash', :opening_balance => '0', :gl_code => '10001',
                           :account_type => @account_type)
    @account.save
    @account.should be_valid
    
    @manager = StaffMember.new(:name => 'Mr Ravan')
    @manager.save
    @manager.should be_valid

    @branch = Branch.new(:name => 'Pune Branch', :code => '213')
    @branch.manager = @manager
    @branch.save
    @branch.should be_valid
  end

  before (:each) do
    @rule_book = RuleBook.new(:name => 'principal repayment', :action => 'principal',
                              :credit_account =>@account ,:debit_account =>@account,:branch =>@branch )
    @rule_book.save
    @rule_book.should be_valid 

  end

  it "name should not be less than 3 charactor" do
    @rule_book.name = "xz"
    @rule_book.should_not be_valid 
  end

  it "credit account & debit account should not be same" do
    @rule_book.credit_account = @account
    @rule_book.debit_account  = @account
    @rule_book.should_not be_valid
  end
end
