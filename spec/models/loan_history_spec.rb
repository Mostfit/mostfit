require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe LoanHistory do

  before(:each) do
  @loanhistory=LoanHistory.new(:loan_id=>123456,:date=>"2001-02-02",:scheduled_outstanding_principal=>800,
  :scheduled_outstanding_total=>900,:actual_outstanding_principal=>820,:actual_outstanding_total=>920 ,:status=>:approved)
  @loan = Loan.new(:id => 123456, :amount => 1000, :interest_rate => 0.2, :installment_frequency     => :weekly, :number_of_installments => 30, :scheduled_first_payment_date => "2000-12-06", :applied_on => "2000-02-01", :scheduled_disbursal_date => "2000-06-13")
  @loanhistory.loan=@loan
  @loanhistory.should be_valid
  end
 it "should not be valid without scheduled outstanding principal" do
	@loanhistory.scheduled_outstanding_principal=nil
	@loanhistory.should_not be_valid
	end
 it "should not be valid without scheduled outstanding total" do
	@loanhistory.scheduled_outstanding_total=nil
	@loanhistory.should_not be_valid
	end
 it "should not be valid without actual outstanding principal" do
	@loanhistory.actual_outstanding_principal=nil
	@loanhistory.should_not be_valid
	end
 it "should not be valid without actual outstanding total" do
	@loanhistory.actual_outstanding_total=nil
	@loanhistory.should_not be_valid
	end
 it "should not be valid without having a proper status" do
	@loanhistory.status="ready"
	@loanhistory.should_not be_valid
	@loanhistory.status=nil
	@loanhistory.should be_valid
	end
 it "should not be valid if the combination if loan id and date is not unique" do
	@loanhistory1=LoanHistory.new(:loan_id=>12345,:date=>"2001-02-02",:scheduled_outstanding_principal=>800,
  :scheduled_outstanding_total=>900,:actual_outstanding_principal=>820,:actual_outstanding_total=>920 ,:status=>:approved)
	@loanhistory1.save
	@loanhistory2=LoanHistory.new(:loan_id=>12345,:date=>"2001-02-02",:scheduled_outstanding_principal=>800,
  :scheduled_outstanding_total=>900,:actual_outstanding_principal=>820,:actual_outstanding_total=>920 ,:status=>:approved)
	@loanhistory2.save	
	@loanhistory2.should_not be_valid
	end
end
