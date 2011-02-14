require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Claim do
  before(:all) do
    load_fixtures :staff_members, :branches, :centers, :client_types, :clients
    @claim = Claim.new
    @claim.date_of_death = Date.today
    @claim.stop_further_installments = false
    @claim.refund_all_payments = false
    client = Client.first
    client.active = false
    @claim.client = client
    @claim.generate_claim_id
    @claim.valid?
    @claim.should be_valid
  end
  
  it "should generate a claim id" do
    @claim.generate_claim_id.should == Date.today.strftime("%Y%m%d") + "#{Client.first.id}"
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
    @claim.date_of_death = Client.first.date_joined - 1
    @claim.should_not be_valid
  end

  it "should not be allowed if payment to client date is before receiving date of claim" do
    @claim.payment_to_client_on = Date.today
    @claim.receipt_of_claim_on  = Date.today + 1
    @claim.should_not be_valid
  end

  it "should not be allowed if client is paid more than the claim amount" do
    @claim.amount_of_claim = 10000
    @claim.amount_to_be_paid_to_client = 10001
    @claim.should_not be_valid
  end

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
