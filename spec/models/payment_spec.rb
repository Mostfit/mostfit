require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Payment do

  before(:all) do
    @user = User.new(:login => 'Joey', :password => 'password', :password_confirmation => 'password', :role => :admin)
    @user.save 
    @user.should be_valid

    @manager = StaffMember.new(:name => "Mrs. M.A. Nerger")
    @manager.save
    @manager.should be_valid

    @funder = Funder.new(:name => "FWWB")
    @funder.save
    @funder.should be_valid

    @funding_line = FundingLine.new(:amount => 10_000_000, :interest_rate => 0.15, :purpose => "for women", 
                                    :disbursal_date => "2006-02-02", :first_payment_date => "2007-05-05", :last_payment_date => "2009-03-03", :id => 1)
    @funding_line.funder = @funder
    @funding_line.save
    @funding_line.should be_valid

    @branch = Branch.new(:name => "Kerela branch", :id => 1)
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

    @client = Client.new(:name => 'Ms C.L. Ient', :reference => 'XW000-2009.01.05', :client_type => ClientType.create(:type => "standard"), :created_by => @user)
    @client.center  = @center
    @client.date_joined = Date.parse('2008-01-01')
    @client.save
    @client.should be_valid
    
    @loan_product = LoanProduct.new
    @loan_product.name = "LP1"
    @loan_product.max_amount = 1000
    @loan_product.min_amount = 1000
    @loan_product.max_interest_rate = 100
    @loan_product.min_interest_rate = 0.1
    @loan_product.installment_frequency = :weekly
    @loan_product.max_number_of_installments = 100
    @loan_product.min_number_of_installments = 25
    @loan_product.loan_type = "DefaultLoan"
    @loan_product.valid_from = Date.parse('2000-01-01')
    @loan_product.valid_upto = Date.parse('2012-01-01')
    @loan_product.save
    @loan_product.errors.each {|e| puts e}
    @loan_product.should be_valid


    @loan = Loan.new(:amount => 1000, :interest_rate => 0.2, :installment_frequency => :weekly, :number_of_installments => 40, :scheduled_first_payment_date => "2000-12-06", :applied_on => "2000-02-01", :scheduled_disbursal_date => "2000-06-13")
    @loan.history_disabled = true
    @loan.applied_by       = @manager
    @loan.funding_line     = @funding_line
    @loan.client           = @client
    @loan.approved_on = "2000-02-03"
    @loan.approved_by = @manager
    @loan.disbursal_date = @loan.scheduled_disbursal_date
    @loan.disbursed_by = @manager
    @loan.loan_product = @loan_product
    @loan.save
    @loan.errors.each {|e| puts e}
    @loan.should be_valid
  end

  before(:each) do
    @user.active = true
    @manager.active = true
    @payment = Payment.new(:amount =>1000,:type => :principal,:received_on=>"2000-12-06")
    @payment.created_by=@user
    @payment.received_by=@manager
    @payment.loan=@loan
    @payment.valid?
    @payment.errors.each {|e| puts e}
    @payment.should be_valid
  end

  it "should not be valid without belonging to a loan" do
    @payment.loan=nil
    @payment.should raise_error
  end
  it "should not be valid without being created by a staff member" do
    @payment.created_by=nil
    @payment.should_not be_valid
  end
  it "should not be valid without being received by a staff member" do
    @payment.received_by=nil
    @payment.should_not be_valid
  end
  it "should not be valid without being created by active user" do
    @user.active=false
    @payment.should_not be_valid
  end
  it "should not be valid without beng received by an active staff member" do
    @manager.active=false
    @payment.should_not be_valid
  end
  it "should not be valid without being properly deleted" do
    @payment.deleted_by=@user
    @payment.deleted_at=nil
    @payment.should_not be_valid
    @payment.deleted_at="2009-02-02"
    @payment.should be_valid	
  end
  it "should not be valid if date of receival is in future" do
    @payment.received_on=Date.new() + 10
    @payment.should_not be_valid	
    @payment.received_on = nil
  end
  it "should not be valid if interest is negative" do
    @payment.amount= -2
    @payment.should_not be_valid
  end
  it "should not be valid if principal is negative" do
    @payment.amount=-600
    @payment.type = :principal
    @payment.should_not be_valid
  end
  it "should not be valid if total is negative" do
    @payment.amount =-1900
    @payment.should_not be_valid
  end
  it "should not be valid if payment is received before disbursal of loan" do
    @payment.received_on = @loan.scheduled_disbursal_date - 1
    @payment.should_not be_valid
  end
  it "should not be valid if paying too much principal" do
    @payment.amount=5000
    @payment.type = :principal
    @payment.should_not be_valid
  end
  it "should not be valid if paying too much interest" do
    @payment.type = :interest
    @payment.amount = 201
    @payment.should_not be_valid
  end



end
