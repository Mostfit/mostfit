require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe AccountLoanObserver do
  
  before(:all) do
    Payment.all.destroy! if Payment.all.count > 0
    Client.all.destroy! if Client.count > 0
    mfi = Mfi.first
    mfi.accounting_enabled = true
    mfi.save

    load_fixtures :account_type, :account, :currency, :journal_types, :credit_account_rule, :debit_account_rule, :rule_book, :staff_members, :users, :funders, :funding_lines, :branches, :centers, :client_types, :clients, :loan_products

    @manager = StaffMember.new(:name => "Mrs. M.A. Nerger")
    @manager.save
    @manager.should be_valid
    @loan_product = LoanProduct.first
    @funding_line = FundingLine.first
    @client       = Client.first
  end
  
  before (:each) do
    Journal.all.destroy!
    Posting.all.destroy!
  end
  
  after(:all) do
    mfi = Mfi.first
    mfi.accounting_enabled = false
    mfi.save
  end
  
  it "should not do journal entry when loan is created" do
    @loan = Loan.new(:amount => 1000, :interest_rate => 0.2, :installment_frequency => :weekly, :number_of_installments => 25, 
                     :scheduled_first_payment_date => "2000-12-06", :applied_on => "2000-02-01", :scheduled_disbursal_date => "2000-06-13")
    @loan.history_disabled = true
    @loan.applied_by       = @manager
    @loan.funding_line     = @funding_line
    @loan.client           = @client
    @loan.loan_product     = @loan_product
    @loan.valid?
    @loan.errors.each {|e| puts e}
    @loan.save
    @loan.should be_valid

    AccountLoanObserver.get_state(@loan)
    AccountLoanObserver.make_posting_entries_on_update(@loan)

    @journal = Journal.last
    @journal.should eql(nil)
    Journal.count.should eql(0)
    Posting.count.should eql(0)
  end


  it "should do journal entry when loan is disbursed during creation" do
    @loan = Loan.new(:amount => 1000, :interest_rate => 0.2, :installment_frequency => :weekly, :number_of_installments => 25, 
                     :scheduled_first_payment_date => "2000-12-06", :applied_on => "2000-02-01", :scheduled_disbursal_date => "2000-06-13",
                     :approved_on => Date.today, :approved_by => @manager, :disbursal_date => Date.today, :disbursed_by => @manager)
    @loan.history_disabled = true
    @loan.applied_by       = @manager
    @loan.funding_line     = @funding_line
    @loan.client           = @client
    @loan.loan_product     = @loan_product
    @loan.errors.each {|e| puts e}
    @loan.save
    @loan.should be_valid
    
    @journal = Journal.first
    @journal.should be_valid
    
    #One journal entry when new loan is created and disbursed simultaneously
    Journal.count.should eql(1)
    Posting.count.should eql(2)
    
    #two journal entries for amount changed
    old_amount = @loan.amount.to_f
    @loan.amount = 5500
    @loan.save
    @loan.should be_valid
    Journal.count.should eql(3)
    Journal.get(Journal.count).postings.first.amount.should eql(@loan.amount.to_f * -1) 
    Journal.get(Journal.count).postings.last.amount.should eql(@loan.amount.to_f)

    Journal.get(Journal.count - 1).postings.first.amount.should eql(old_amount) 
    Journal.get(Journal.count - 1).postings.last.amount.should eql(old_amount * -1) 
    
    #No journal entry when amount is unchanged
    old_amount = @loan.amount.to_f
    @loan.amount = old_amount
    @loan.save
    @loan.should be_valid
    Journal.count.should eql(3) 

    #two journal entries for disbursal date changed
    old_disbursal_date = @loan.disbursal_date
    @loan.disbursal_date = Date.today + 5
    @loan.save
    @loan.should be_valid
    Journal.count.should eql(5)  
    Journal.get(Journal.count - 1).date.strftime("%d-%m-%Y").should eql(old_disbursal_date.strftime("%d-%m-%Y")) 
    Journal.get(Journal.count).date.strftime("%d-%m-%Y").should eql(@loan.disbursal_date.strftime("%d-%m-%Y"))

    #No journal entry when disbursal date is unchanged
    old_disbursal_date = @loan.disbursal_date
    @loan.disbursal_date = old_disbursal_date
    @loan.save
    @loan.should be_valid
    Journal.count.should eql(5) 

    #One journal entry for loan unset
    @loan.disbursal_date = nil
    @loan.disbursed_by = nil
    @loan.save
    @loan.should be_valid
    Journal.count.should eql(6)  

    #No Journal entry when amount is set to nil 
    @loan.amount = nil
    @loan.save
    @loan.should_not be_valid
    Journal.count.should eql(6)  

    Posting.count.should eql(Journal.count * 2)
  end
end

