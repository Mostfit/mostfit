require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Journal do
  before (:all) do
    load_fixtures :account_type, :account, :currency, :journal_type
  end
  
  it "should create double entry transactions correctly" do
    journal = {:date => Time.now, :transaction_id => "1100110", :currency => Currency.first, :amount => 1000, :journal_type_id => Journal.first.id}
    journal[:comment] = "some transaction"
    old_journal_count = Journal.count
    old_posting_count = Posting.count
    debit_account = Account.first 
    credit_account = Account.last
    status, journal = Journal.create_transaction(journal, debit_account, credit_account)
    status.should be_true
    journal.should be_valid
    journal.postings.count.should == 2
    debit, credit = journal.postings.sort_by{|x| x.amount}
    debit.amount.should == -1000
    credit.amount.should == 1000
    debit.account.should == debit_account
    credit.account.should == credit_account
    Journal.count.should == old_journal_count+1
    Posting.count.should == old_posting_count+2
  end

  it "should not be valid if both accounts are same" do
    journal = {:date => Time.now, :transaction_id => "1100110", :currency => Currency.first, :amount => 1000, :journal_type_id => Journal.first.id}
    journal[:comment] = "some transaction"
    old_journal_count = Journal.count
    debit_account = Account.first 
    credit_account = Account.first
    status, journal = Journal.create_transaction(journal, debit_account, credit_account)
    status.should be_false
    Journal.count.should == old_journal_count
  end

  it "should not be valid if amount is zero" do
    journal = {:date => Time.now, :transaction_id => "1100110", :currency => Currency.first, :amount => 0, :journal_type_id => Journal.first.id}
    journal[:comment] = "some transaction"
    old_journal_count = Journal.count
    debit_account = Account.first
    credit_account = Account.first
    status, journal = Journal.create_transaction(journal, debit_account, credit_account)
    status.should be_false
    Journal.count.should == old_journal_count
  end
end
