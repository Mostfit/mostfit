require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Posting do
  before (:all) do
    @account_type = AccountType.new(:name => "Assets", :code => "AST")
    @account_type.save
    @account_type.errors
    @account_type.should be_valid
    
    @journal  = Journal.new(:comment => "A principal is repayed", :transaction_id => 100, :date => Date.today, :created_at => Date.today)
    @journal.save
    @journal.errors
    @journal.should be_valid
    
    @account  = Account.new(:name => "Income Account", :gl_code => "IA1002", :account_type => @account_type)
    @account.save
    @account.errors
    @account.should be_valid
    
    @currency = Currency.new(:name => "INR")
    @currency.save
    @currency.errors
    @currency.should be_valid
  end
  
  before (:each) do
    Posting.all.destroy!
    @posting = Posting.new(:amount => 0, :journal => @journal, :account => @account, :currency => @currency) 
  end
  
  it "should contain a journal" do
    @posting.journal = nil
    @posting.should_not be_valid
  end
  
  it "should contain an account" do
    @posting.account = nil
    @posting.should_not be_valid
  end
  
  it "should contain a currency" do
    @posting.currency = nil
    @posting.should_not be_valid
  end
end
