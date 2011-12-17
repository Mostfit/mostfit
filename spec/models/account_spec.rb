require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Account do

  before(:all) do
    Account.all.destroy!
  end

  before(:each) do
    @account = Factory.build( :account, :name => "Cash Account", :gl_code => "CA1001", :opening_balance_on_date => Date.today )
  end

  it "should be valid with default attributes" do
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

=begin
Scenario 1: If an account was set with an opening_balance on a particular date

It cannot have any opening balances on dates that are earlier than such date

Scenario 2: Consider a sequence of dates as follows:

a0, a1, a2, etc. are accounting periods; a0b, a0e are accounting period begin and end dates
a0b, d0, a0e, a1b, ob, d1, a1e, a2b, d2, a2e, a3b, d3, a3e
Opening balance B is set on date ob

Opening balances on dates is as follows:
d0 = nil
d1 = B + sum(postings since ob till d1)

If a2b has opening balance set
d2 = opening_balance(a2) + sum(postings since a2b till d2)

if a2b has no opening balance set
d2 = ob + sum(postings since ob till d2)

If an account was not set with an opening_balance on a particular date
Opening balance on any date = opening balance on the most recent accounting period that has a balance for the account + sum(postings since begin date of such accounting period till date) 

=end

  it "should be able to 'have' account" do
    @child_account = Factory.build(:account, :name => "Income Account", :gl_code => "IA1002", :account_type => @account.account_type, :opening_balance_on_date => Date.today)
    @child_account.should be_valid
    @account.account = @child_account
    @account.should be_valid
  end

  it "should be valid with or without branch" do
    @account.branch = Factory.build(:branch)
    @account.should be_valid
    @account.branch = nil
    @account.should be_valid
  end
end
