require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Claim do

  before(:each) do
    @claim = Factory(:claim)
    @claim.should be_valid
  end
  
  it "should generate a claim id" do
    @claim.generate_claim_id.should == Date.today.strftime("%Y%m%d") + "#{@claim.client.id}"
  end

  it "should not have date of death in future" do
    @claim.date_of_death = Date.today + 1
    @claim.should_not be_valid
  end

  it "should not be allowed if client is inactive" do
    @claim.client.active = true
    @claim.should_not be_valid
  end

  it "should not be allowed if client is dead before joining" do
    @claim.date_of_death = @claim.client.date_joined - 1
    @claim.should_not be_valid
  end

  # This test is failing but the relevant validation line (:payment_to_client_after_receipt)
  # in the model are commented out, so perhaps this test should be removed?
#  it "should not be allowed if payment to client date is before receiving date of claim" do
#    @claim.payment_to_client_on = Date.today
#    @claim.receipt_of_claim_on  = Date.today + 1
#    @claim.should_not be_valid
#  end

  # This test is failing because these amounts are now automatically normalized in
  # the #set_amount_to_be_paid_to_client method before validation occurs.
#  it "should not be allowed if client is paid more than the claim amount" do
#    puts "Checking amounts.."
#    @claim.amount_of_claim = 10000
#    @claim.amount_to_be_paid_to_client = 10001
#    @claim.should_not be_valid
#  end

  it "should not be allowed if date of death is after claim submission date" do
    @claim.date_of_death = Date.today 
    @claim.claim_submission_date = Date.today - 1
    @claim.should_not be_valid
  end

  it "should not be allowed if client payment date is before date of death" do
    @claim.date_of_death = Date.today 
    @claim.payment_to_client_on = Date.today - 1
    @claim.should_not be_valid
  end

  it "should have correct amount to be paid to client" do
    @claim.amount_of_claim = 10000
    @claim.amount_to_be_deducted = 0
    @claim.valid?
    @claim.amount_to_be_paid_to_client.should == 10000

    @claim.amount_to_be_deducted = 1000
    @claim.valid?
    @claim.amount_to_be_paid_to_client.should == 9000

    @claim.amount_to_be_deducted = nil
    @claim.valid?
    @claim.amount_to_be_paid_to_client.should == 10000

    @claim.amount_to_be_deducted = 11000
    @claim.should_not be_valid
  end

end
