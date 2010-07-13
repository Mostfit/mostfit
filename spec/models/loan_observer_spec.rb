require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe LoanObserver do
  
  before(:all) do
    load_fixtures :account_type, :account, :currency, :journal_type, :rule_book
    Payment.all.destroy! if Payment.all.count > 0
    Client.all.destroy! if Client.count > 0
    @user = User.new(:login => 'Joey', :password => 'password', :password_confirmation => 'password', :role => :admin)
    @user.save
    @user.should be_valid

    @manager = StaffMember.new(:name => "Mrs. M.A. Nerger")
    @manager.save
    @manager.should be_valid

    @funder = Funder.new(:name => "FWWB")
    @funder.save
    @funder.should be_valid

    @funding_line = FundingLine.new(:amount => 10_000_000, :interest_rate => 0.15, :purpose => "for women", :disbursal_date => "2006-02-02", :first_payment_date => "2007-05-05", :last_payment_date => "2009-03-03")
    @funding_line.funder = @funder
    @funding_line.save
    @funding_line.should be_valid

    @branch = Branch.new(:name => "Kerela branch")
    @branch.manager = @manager
    @branch.code = "bra"
    @branch.save
    @branch.should be_valid

    @center = Center.new(:name => "Munnar hill center")
    @center.manager = @manager
    @center.branch  = @branch
    @center.code = "cen"
    @center.save
    @center.should be_valid

    @client = Client.new(:name => 'Ms C.L. Ient', :reference => Time.now.to_s, :client_type => ClientType.create(:type => "Standard"))
    @client.center  = @center
    @client.date_joined = Date.parse('2006-01-01')
    @client.created_by_user_id = 1
    @client.client_type_id = 1
    @client.save
    @client.errors.each {|e| puts e}
    @client.should be_valid
    # validation needs to check for uniqueness, therefor calls the db, therefor we dont do it
    @loan_product = LoanProduct.new
    @loan_product.name = "LP1"
    @loan_product.max_amount = 10000
    @loan_product.min_amount = 0
    @loan_product.max_interest_rate = 100
    @loan_product.min_interest_rate = 0.1
    @loan_product.installment_frequency = :weekly
    @loan_product.max_number_of_installments = 25
    @loan_product.min_number_of_installments = 25
    @loan_product.loan_type = "DefaultLoan"
    @loan_product.valid_from = Date.parse('2000-01-01')
    @loan_product.valid_upto = Date.parse('2012-01-01')
    @loan_product.save
    @loan_product.errors.each {|e| puts e}
    @loan_product.should be_valid
  end
  
  before (:each) do
    Journal.all.destroy!
    Posting.all.destroy!
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
    Journal.get(Journal.count - 1).postings.first.amount.should eql(old_amount) 
    Journal.get(Journal.count - 1).postings.last.amount.should eql(old_amount * -1) 
    Journal.get(Journal.count).postings.first.amount.should eql(@loan.amount.to_f * -1) 
    Journal.get(Journal.count).postings.last.amount.should eql(@loan.amount.to_f)
    
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

