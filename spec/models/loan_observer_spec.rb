require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe AccountLoanObserver do
  
  before(:all) do
    mfi = Mfi.first
    mfi.accounting_enabled = true
    mfi.save

    @manager = Factory(:staff_member)
    @manager.should be_valid

    @loan_product = Factory(:loan_product)
    @loan_product.should be_valid

    @funding_line = Factory(:funding_line)
    @funding_line.should be_valid

    @client = Factory(:client)
    @client.should be_valid
  end
  
  after(:all) do
    mfi = Mfi.first
    mfi.accounting_enabled = false
    mfi.save
  end

  before (:each) do
    Journal.all.destroy!
    Posting.all.destroy!
  end

  # This test is passing but probably in error, see below
  it "should not do journal entry when loan is created" do
    loan = Factory(:loan, :history_disabled => true)
    loan.should be_valid

    AccountLoanObserver.get_state(loan)
    AccountLoanObserver.make_posting_entries_on_update(loan)

    journal = Journal.last
    journal.should eql(nil)
    Journal.count.should eql(0)
    Posting.count.should eql(0)
  end

  # Loans are not creating Journals on save, but so far I haven't found out why.
#
#  context "when loan is disbursed during creation" do
#    before(:each) do
#      @loan = Factory.build(:loan,
#        :amount => 1000, :interest_rate => 0.2, :installment_frequency => :weekly, :number_of_installments => 25,
#        :scheduled_first_payment_date => "2000-12-06", :applied_on => "2000-02-01", :scheduled_disbursal_date => "2000-06-13",
#        :approved_on => Date.today, :approved_by => @manager, :disbursal_date => Date.today, :disbursed_by => @manager, :history_disabled => true )
#      @loan.should be_valid
#    end
#
#    it "should create a journal entry when disbursed" do
#      @loan.save
#
#      journal = Journal.first
#      journal.should be_valid
#
#      # One journal entry when new loan is created and disbursed simultaneously
#      Journal.count.should eql(1)
#      Posting.count.should eql(2)
#    end
#
#    it "should create two journal entries when the amount changes" do
#      lambda {
#        old_amount = @loan.amount.to_f
#        @loan.amount = 5500
#        @loan.should be_valid
#        @loan.save
#      }.should change(Journal, :count).by(2)
#
#      Journal.last.postings.first.amount.should eql(@loan.amount.to_f * -1) 
#      Journal.last.postings.last.amount.should eql(@loan.amount.to_f)
#
#      Journal.first.postings.first.amount.should eql(old_amount) 
#      Journal.first.postings.last.amount.should eql(old_amount * -1) 
#    end
#
#    it "should create no journal entries when the amount is unchanged" do
#      #No journal entry when amount is unchanged
#      old_amount = @loan.amount.to_f
#      @loan.amount = old_amount
#      @loan.save
#      @loan.should be_valid
#      Journal.count.should eql(3)
#    end
#
#    it "should create two journal entries when the disbursal date changes" do
#      #two journal entries for disbursal date changed
#      old_disbursal_date = @loan.disbursal_date
#      @loan.disbursal_date = Date.today + 5
#      @loan.save
#      @loan.should be_valid
#      Journal.count.should eql(5)  
#      Journal.get(Journal.count - 1).date.strftime("%d-%m-%Y").should eql(old_disbursal_date.strftime("%d-%m-%Y")) 
#      Journal.get(Journal.count).date.strftime("%d-%m-%Y").should eql(@loan.disbursal_date.strftime("%d-%m-%Y"))
#    end
#
#    it "should create no journal entries when the disbursal date is unchanged" do
#      #No journal entry when disbursal date is unchanged
#      old_disbursal_date = @loan.disbursal_date
#      @loan.disbursal_date = old_disbursal_date
#      @loan.save
#      @loan.should be_valid
#      Journal.count.should eql(5)
#    end
#
#    it "should create one journal entry when the loan is unset" do
#      #One journal entry for @loan unset
#      @loan.disbursal_date = nil
#      @loan.disbursed_by = nil
#      @loan.save
#      @loan.should be_valid
#      Journal.count.should eql(6)  
#    end
#
#    it "should create no journal entry when the amount is nil" do
#      #No Journal entry when amount is set to nil 
#      @loan.amount = nil
#      @loan.save
#      @loan.should_not be_valid
#      Journal.count.should eql(6)  
#
#      Posting.count.should eql(Journal.count * 2)
#    end
#  end
end

