require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe RuleBook do
 
  before (:all) do
    @account_type = AccountType.new(:name => 'Assets',:code => '20000')
    @account_type.save
    @account_type.should be_valid 
    
    @credit_account = Account.new(:name => 'petty cash', :opening_balance => '0', :gl_code => '10001',
                           :account_type => @account_type)
    @credit_account.save
    @credit_account.should be_valid

    @debit_account = Account.new(:name => 'income account', :opening_balance => '0', :gl_code => '20002',
                           :account_type => @account_type)
    @debit_account.save
    @debit_account.should be_valid
    
    @manager = StaffMember.new(:name => 'Mr Ravan')
    @manager.save
    @manager.should be_valid

    @branch = Branch.new(:name => 'Pune Branch', :code => '213')
    @branch.manager = @manager
    @branch.save
    @branch.should be_valid
  end

  before (:each) do
    @rule_book = RuleBook.new(:name => "principal repayment", :action => 'principal',
                              :credit_account => @credit_account ,:debit_account => @debit_account,:branch =>@branch)
    @rule_book.save
    @rule_book.errors
    @rule_book.should be_valid 
  end

  it "should not be valid if name is less than 3 character" do
    @rule_book.name = "xz"
    @rule_book.should_not be_valid 
  end
  
  it "should not be valid if credit account and debit account is same" do
    @rule_book.credit_account = @credit_account
    @rule_book.debit_account  = @credit_account
    @rule_book.should_not be_valid
  end
  
end
