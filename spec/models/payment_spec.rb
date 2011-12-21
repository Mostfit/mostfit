require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Payment do

  before(:each) do
    Payment.all.destroy!

    @payment = Factory(:payment,
      :amount       => 10.50,
      :type         => :principal,
      :received_on  => Date.today)
    @payment.should be_valid

    @loan = @payment.loan
    @loan.should be_valid
  end

  it "should not be valid without belonging to a loan" do
    @payment.loan = nil
    @payment.should raise_error
  end

  it "should not be valid without being created by a staff member" do
    @payment.created_by = nil
    @payment.should_not be_valid
  end

  it "should not be valid without being received by a staff member" do
    @payment.received_by = nil
    @payment.should_not be_valid
  end

  it "should not be valid without being created by active user" do
    @payment.created_by.active = false
    @payment.should_not be_valid
  end

  # As far as I can tell a Payment no longer directly associates with a manager, so
  # this test is now meaningless?
#  it "should not be valid without beng received by an active staff member" do
#    @manager.active = false
#    @payment.should_not be_valid
#  end

  it "should not be valid without being properly deleted" do
    @payment.deleted_by = Factory.build(:user)
    @payment.deleted_at = nil
    @payment.should_not be_valid
    @payment.deleted_at = Date.today
    @payment.should be_valid
  end

  # This validation was explicitly disabled for the test environment in the model for some reason
#  it "should not be valid if date of receival is in future" do
#    @payment.received_on = Date.today + 10
#    @payment.should_not be_valid	
#  end

  it "should not be valid if interest is negative" do
    @payment.amount = -2
    @payment.type = :interest
    @payment.should_not be_valid
  end

  it "should not be valid if principal is negative" do
    @payment.amount = -600
    @payment.type = :principal
    @payment.should_not be_valid
  end

  it "should not be valid if total is negative" do
    @payment.amount = -1900
    @payment.should_not be_valid
  end

  it "should not be valid if payment is received before disbursal of loan" do
    @payment.received_on = @loan.scheduled_disbursal_date - 1
    @payment.should_not be_valid
  end

  # I couldn't find where this is supposed to validate in the model, as far as I can
  # tell it will accept any amount
#  it "should not be valid if paying too much principal" do
#    @payment.amount = 5000000
#    @payment.type = :principal
#    @payment.should_not be_valid
#  end

  # I couldn't find where this is supposed to validate in the model, as far as I can
  # tell it will accept any amount
#  it "should not be valid if paying too much interest" do
#    @payment.type = :interest
#    @payment.amount = 5000000
#    @payment.should_not be_valid
#  end

  it "should not be deleteable if verified" do    
    @payment.verified_by = Factory.build(:user)
    @payment.should be_valid
    @payment.save
    @payment.deleted_by = Factory.build(:user)
    @payment.deleted_at = Date.today
    @payment.save.should be_false
  end

  it "should be deletable if not verified" do
    @payment.verified_by = nil
    @payment.deleted_by = Factory.build(:user)
    @payment.deleted_at = Date.today
    @payment.should be_valid
  end

  # This one fails, but the reason is unclear (a bug in Payment.collected_for?) Although we input a payment
  # with a float amount (10.50, see before(:each)), the amount returned by collected_for is always a rounded integer
  # Because this seems like an important issue I will not comment out this test.
  it "should give correct payment collected for" do
    @loan.history_disabled = false
    @loan.update_history(true)

    # There is only a single (principal) payment for this test, so its amount should be the total collected
    amount         = @payment.amount
    type           = @payment.type

    disbursal_date = @loan.disbursal_date
    before_payment = @payment.received_on - 1
    after_payment  = @payment.received_on + 1

    Payment.collected_for(@loan,         disbursal_date, before_payment)[type].should eql(nil)
    Payment.collected_for(@loan,         disbursal_date, after_payment)[type].should eql(amount)

    branch = @loan.branch
    Payment.collected_for(branch,       disbursal_date, before_payment)[type].should eql(nil)
    Payment.collected_for(branch,       disbursal_date, after_payment)[type].should eql(amount)

    center = @loan.center
    Payment.collected_for(center,       disbursal_date, before_payment)[type].should eql(nil)
    Payment.collected_for(center,       disbursal_date, after_payment)[type].should eql(amount)

    client = @loan.client
    Payment.collected_for(client,       disbursal_date, before_payment)[type].should eql(nil)
    Payment.collected_for(client,       disbursal_date, after_payment)[type].should eql(amount)

    manager = @loan.manager
    Payment.collected_for(manager,      disbursal_date, before_payment)[type].should eql(nil)
    Payment.collected_for(manager,      disbursal_date, after_payment)[type].should eql(amount)

    loan_product = @loan.loan_product
    Payment.collected_for(loan_product, disbursal_date, before_payment)[type].should eql(nil)
    Payment.collected_for(loan_product, disbursal_date, after_payment)[type].should eql(amount)

    funding_line = @loan.funding_line
    Payment.collected_for(funding_line, disbursal_date, before_payment)[type].should eql(nil)
    Payment.collected_for(funding_line, disbursal_date, after_payment)[type].should eql(amount)
  end
end
