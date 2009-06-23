require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Payment do

  before(:each) do

    @payment = Payment.new(:principal=>1000,:interest=>0.2,:received_on=>"2000-12-06")
		       
    @user = User.new(:id => 234, :login => 'Joey User', :password => 'password', :password_confirmation => 'password')
    # validation needs to check for uniqueness, therefor calls the db, therefor we dont do it

    @manager = StaffMember.new(:name => "Mrs. M.A. Nerger")
    # validation needs to check for uniqueness, therefor calls the db, therefor we dont do it

    @funder = Funder.new(:name => "FWWB")
    @funder.should be_valid

    @funding_line = FundingLine.new(:amount => 10_000_000, :interest_rate => 0.15, :purpose => "for women", :disbursal_date => "2006-02-02", :first_payment_date => "2007-05-05", :last_payment_date => "2009-03-03")
    @funding_line.funder = @funder
    @funding_line.should be_valid

    @branch = Branch.new(:name => "Kerela branch")
    @branch.manager = @manager
    @branch.should be_valid

    @center = Center.new(:name => "Munnar hill center")
    @center.manager = @manager
    @center.branch  = @branch
    @center.should be_valid

    @client = Client.new(:name => 'Ms C.L. Ient', :reference => 'XW000-2009.01.05')
    @client.center  = @center
    # validation needs to check for uniqueness, therefor calls the db, therefor we dont do it

    @loan = Loan.new(:id => 123456, :amount => 1000, :interest_rate => 0.2, :installment_frequency => :weekly, :number_of_installments => 30, :scheduled_first_payment_date => "2000-12-06", :applied_on => "2000-02-01", :scheduled_disbursal_date => "2000-06-13")
    @loan.history_disabled = true
    @loan.applied_by       = @manager
    @loan.funding_line     = @funding_line
    @loan.client           = @client
    @loan.should be_valid
    
    @loan.approved_on = "2000-02-03"
    @loan.approved_by = @manager
    @loan.should be_valid
    @payment.created_by=@user
    @payment.deleted_by=@user
    @payment.received_by=@manager
    @payment.loan=@loan
    @payment.should be_valid


  end

  it "should not be valid without belonging to a loan" do
	@payment.loan=nil
	@payment.should_not be_valid
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
	@payment.deleted_by=nil
	@payment.should_not be_valid
	@payment.deleted_at=nil
	@payment.should be_valid
	@payment.deleted_by=@user
	@payment.deleted_at="2009-02-02"
	@payment.should be_valid	
	end
  it "should not be valid if date of receival is in future" do
	@payment.received_on=Date.new() + 10
	@payment.should_not be_valid	
	end
  it "should not be valid if interest is negative" do
	@payment.interest= -0.2
	@payment.should_not be_valid
	end
  it "should not be valid if principal is negative" do
	@payment.interest=-600
	@payment.should_not be_valid
	end
  it "should not be valid if total is negative" do
	@payment.total=-1900
	@payment.should_not be_valid
	end
  it "should not be valid if payment is received before disbursal of loan" do
	@loan.scheduled_disbursal_date=Date.new()
	@payment.should_not be_valid
	end
  it "should not be valid if paying too much principal" do
	@payment.principal=5000
	@payment.should_not be_valid
	end
  it "should not be valid if paying too much in total" do
	@payment.total=9000
	@payment.should_not be_valid
	end



end
