require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Posting do
  before (:all) do
    load_fixtures :account_type, :account, :rule_book  
    Payment.all.destroy! if Payment.all.count > 0

    @user = User.new(:login => 'Joey', :password => 'password', :password_confirmation => 'password', :role => :admin)
    @user.save
    @user.errors
    @user.should be_valid

    @manager = StaffMember.new(:name => "Mrs. M.A. Nerger")
    @manager.save
    @manager.errors
    @manager.should be_valid

    @funder = Funder.new(:name => "FWWB")
    @funder.save
    @funder.errors
    @funder.should be_valid

    @funding_line = FundingLine.new(:amount => 10_000_000, :interest_rate => 0.15, :purpose => "for women", :disbursal_date => "2006-02-02", 
                                    :first_payment_date => "2007-05-05", :last_payment_date => "2009-03-03")
    @funding_line.funder = @funder
    @funding_line.save
    @funding_line.should be_valid

    @branch = Branch.new(:name => "Kerela branch")
    @branch.manager = @manager
    @branch.code = "ker"
    @branch.save
    @branch.errors
    @branch.should be_valid

    @center = Center.new(:name => "Munnar hill center")
    @center.manager = @manager
    @center.branch  = @branch
    @center.code = "mun"
    @center.save
    @center.should be_valid

    @client = Client.new(:name => 'Ms C.L. Ient', :reference => Time.now.to_s)
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
    @loan_product.max_amount = 1000
    @loan_product.min_amount = 1000
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

    @loan = DefaultLoan.new(:amount => 1000, :interest_rate => 0.2, :installment_frequency => :weekly, :number_of_installments => 25, 
                     :scheduled_first_payment_date => "2000-12-06", :applied_on => "2000-02-01", :scheduled_disbursal_date => "2000-06-13")
    @loan.history_disabled = true
    @loan.applied_by       = @manager
    @loan.funding_line     = @funding_line
    @loan.client           = @client
    @loan.loan_product     = @loan_product
    @loan.valid?
    @loan.save
    @loan.errors.each {|e| puts e}
    @loan.should be_valid
    @loan.approved_on = "2000-02-03"
    @loan.approved_by = @manager
    @loan.should be_valid

    @loan.disbursal_date = "2000-03-04"
    @loan.disbursed_by = @manager
    @loan.save
    @loan.errors
    @loan.should be_valid

  end
  
  before(:each) do
    @user.active = true
    @manager.active = true
    @payment = Payment.new(:amount =>1000,:type => :principal,:received_on=>"2000-04-05")
    @payment.created_by=@user
    @payment.received_by=@manager
    @payment.loan=@loan
    @payment.valid?
    @payment.save
    @payment.errors.each {|e| puts e}
    @payment.should be_valid
  end

  it "should not be valid if book keeping entry are not made on loan disbursal" do
    @journal = Journal.first(:transaction_id => @loan.id)
    @journal.errors
    @journal.should_not == nil

    @debit_posting, @credit_posting = @journal.postings

    @credit_posting.should_not == nil
    @debit_posting.should_not == nil
  end

  
  it "should not be valid if proper book keeping entry are not made on reverse entry" do
    @loan.disbursal_date = nil
    @loan.disbursed_by = nil
    @loan.save
    @loan.should be_valid

    @journal = Journal.last(:transaction_id => @loan.id)
    @debit_posting, @credit_posting = @journal.postings
    @journal.should be_valid
    @credit_posting.should be_valid
    @debit_posting.should be_valid

    @loan.disbursal_date = "2000-03-04"
    @loan.disbursed_by = @manager
    @loan.save
  end

  it "should be valid if book keeping entry are made on payment" do
    @journal = Journal.first(:transaction_id => @payment.id)
    @journal.errors
    @journal.should be_valid    

    @debit_posting, @credit_posting = @journal.postings
    @credit_posting.should be_valid
    @debit_posting.should be_valid
  end

  it "should not be valid if amount in credit_account and debit_account are different in magnitude" do
    @journal = Journal.first(:transaction_id => @payment.id)
    @debit_posting, @credit_posting = @journal.postings
    (@debit_posting.amount + @credit_posting.amount).should == 0
  end

  it "should not be valid if both the posting entries are not made" do
    @journal = Journal.first(:transaction_id => @payment.id)
    @debit_posting, @credit_posting = @journal.postings
    @debit_posting.should_not == nil
    @credit_posting.should_not == nil
  end

  it "should do forward and reverse book keeping entry When disbursal_date is changed" do
    @loan.disbursal_date = "2000-04-05"
    @loan.save
    @journal = Journal.last(:transaction_id => @payment.id)
    @debit_posting, @credit_posting = @journal.postings
    @debit_posting.should_not == nil
    @credit_posting.should_not == nil
  end
end
