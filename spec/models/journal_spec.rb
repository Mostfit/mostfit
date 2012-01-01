require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Journal do

  before(:each) do
    @currency = Factory(:currency)
    @journal_Type = Factory(:journal_type)
  end
  
  it "should create double entry transactions correctly" do
    journal = {:date => Time.now, :transaction_id => "1100110", :currency => @currency, :amount => 1000, :journal_type_id => @journal_type.id, :comment => "some transaction"}

    old_journal_count = Journal.count
    old_posting_count = Posting.count

    debit_account = Factory(:account, :name => 'Debit account', :opening_balance => 0)
    credit_account = Factory(:account, :name => 'Credit account', :opening_balance => 0)

    credit_account.branch_id = nil
    debit_account.branch_id = nil

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

  it "should create double entry transactions for multipl credit and debit accounts" do
    journal = {:date => Time.now, :transaction_id => "1100110", :currency => @currency, :journal_type_id => @journal_type.id, :comment => "some transaction"}

    old_journal_count = Journal.count
    old_posting_count = Posting.count

    # We create one credit account to receive the total amount and two debit accounts to take the partial amounts from
    credit_accounts = { Factory(:account, :name => 'credit account', :opening_balance => 0) => 500 }
    debit_accounts  = {
      Factory(:account, :name => 'debit account 1', :opening_balance => 0) => 100,
      Factory(:account, :name => 'debit account 2', :opening_balance => 0) => 400,
    }

    status, journal = Journal.create_transaction(journal, debit_accounts, credit_accounts)
    status.should be_true
    journal.should be_valid
    journal.postings.count.should == 3

    debits, credits = journal.postings.group_by{|x| x.amount>0}.values
    debits.map{|x| x.amount}.inject(0){|s,x| s+=x}.should == -500
    credits.map{|x| x.amount}.inject(0){|s,x| s+=x}.should == 500

    Journal.count.should == old_journal_count+1
    Posting.count.should == old_posting_count+3
  end

  it "should not be valid if both accounts are same" do
    journal = {:date => Time.now, :transaction_id => "1100110", :currency => @currency, :amount => 1000, :journal_type_id => @journal_type.id, :comment => "some transaction"}

    # Make the debit and credit accounts the same account
    debit_account = credit_account = Factory(:account, :name => 'duplicate account')

    lambda {
      status, journal = Journal.create_transaction(journal, debit_account, credit_account)
      status.should be_false
    }.should change(Journal, :count).by(0)
  end

  it "should not be valid if amount is zero" do
    journal = {:date => Time.now, :transaction_id => "1100110", :currency => @currency, :amount => 0, :journal_type_id => @journal_type.id, :comment => "some transaction" }

    debit_account = Factory(:account, :name => 'Debit account', :opening_balance => 0)
    credit_account = Factory(:account, :name => 'Credit account', :opening_balance => 0)

    lambda {
      status, journal = Journal.create_transaction(journal, debit_account, credit_account)
      status.should be_false
    }.should change(Journal, :count).by(0)
  end

  it "should not be valid if accounts are of different branches" do
    journal = {:date => Time.now, :transaction_id => "1100110", :currency => @currency, :amount => 1000, :journal_type_id => @journal_type.id, :comment => "some transaction" }

    debit_account = Factory(:account, :name => 'Debit account', :opening_balance => 0)
    credit_account = Factory(:account, :name => 'Credit account', :opening_balance => 0)

    # Assign a different branch to each account
    debit_account.branch  = Factory(:branch)
    credit_account.branch = Factory(:branch)

    lambda {
      status, journal = Journal.create_transaction(journal, debit_account, credit_account)
      status.should be_false
    }.should change(Journal, :count).by(0)
  end
end
