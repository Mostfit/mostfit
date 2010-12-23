require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe RuleBook do
  before (:all) do
    Branch.all.destroy!

    @account_type = AccountType.new(:name => 'Assets',:code => 'AST')
    @account_type.save
    @account_type.should be_valid 
    
    @credit_account = Account.new(:name => 'petty cash', :opening_balance => '0', :gl_code => '10001',
                                  :account_type => @account_type, :opening_balance_on_date => Date.today)
    @credit_account.save
    @credit_account.should be_valid

    @debit_account = Account.new(:name => 'income account', :opening_balance => '0', :gl_code => '20002',
                                 :account_type => @account_type,  :opening_balance_on_date => Date.today) 
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
    RuleBook.all.destroy!
    @rule_book = RuleBook.new(:name => "principal repayment", :action => 'principal', :branch => @branch, :fee_id => 0)
    @rule_book.credit_account_rules << CreditAccountRule.create(:credit_account => @credit_account, :percentage => 100)
    @rule_book.debit_account_rules  << DebitAccountRule.create(:debit_account => @debit_account,  :percentage => 100)
    @rule_book.from_date = "2010.1.1"
    @rule_book.to_date = "2010.12.1"
    @rule_book.created_by_user_id = 1
    @rule_book.save
    @rule_book.errors.each{|e| puts e}
    @rule_book.should be_valid
  end
  
  it "should not be valid if name is less than 3 character" do
    @rule_book.name = "xz"
    @rule_book.should_not be_valid 
  end
  
  it "should not be valid if credit account and debit account is same" do
    @rule_book.credit_accounts << @credit_account
    @rule_book.debit_accounts  << @credit_account
    @rule_book.should_not be_valid
  end
  
  it "should not be valid if same action exist twice for a branch" do
    @rule_book_2 = RuleBook.new(:name => "principal repayment", :action => 'principal',:branch =>@branch)
    @rule_book.credit_account_rules << CreditAccountRule.create(:credit_account => @credit_account, :percentage => 100)
    @rule_book.debit_account_rules  << DebitAccountRule.create(:debit_account => @debit_account,  :percentage => 100)
    @rule_book_2.created_by_user_id = 1
    @rule_book_2.save
    @rule_book_2.errors.each{|e| puts e}
    @rule_book_2.should_not be_valid 
  end
  
  it "should update old rule if same new rule is been created" do
    
    @rule_book_1 = RuleBook.new(:name => "principal repayment1", :action => 'principal', :branch => @branch, :fee_id => 0)
    @rule_book_1.credit_account_rules << CreditAccountRule.create(:credit_account => @credit_account, :percentage => 100)
    @rule_book_1.debit_account_rules  << DebitAccountRule.create(:debit_account => @debit_account,  :percentage => 100)
    @rule_book_1.from_date = "2010.10.1"
    @rule_book_1.to_date = "2010.12.1"
    @rule_book_1.created_by_user_id = 1
    @rule_book_1.save
    @rule_book_1.errors.each{|e| puts e}
    @rule_book_1.should be_valid
    @rule_book.to_date = "2010.9.30"
    @rule_book.active = false
    @rule_book.save
    @rule_book.should be_valid
  end

  it "should not create rule if from_date is greater than to_date" do

    @rule_book3 = RuleBook.new(:name => "principal repayment test", :action => 'principal', :branch => @branch, :fee_id => 0)
    @rule_book3.credit_account_rules << CreditAccountRule.create(:credit_account => @credit_account, :percentage => 100)
    @rule_book3.debit_account_rules  << DebitAccountRule.create(:debit_account => @debit_account,  :percentage => 100)
    @rule_book3.from_date = "2010.12.1" 
    @rule_book3.to_date = "2010.1.1"
    @rule_book3.created_by_user_id = 1
    @rule_book3.save
    @rule_book3.errors.each{|e| puts e}
    @rule_book3.should_not be_valid
  end
  
end
