require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe FundingLine do

  before(:each) do
  @afunder=Funder.new(:id=>10,:name=>"sparsh")
  @afunder.should be_valid
  @afundingline= FundingLine.new(:amount => 10_000_000, :interest_rate => 0.15, :purpose => "for women", :disbursal_date => 	"2006-02-02", :first_payment_date => "2007-05-05", :last_payment_date => "2009-03-03")
  @afundingline.funder=@afunder
  @afundingline.should be_valid
  end
 it "should not be valid without belonging to a funder" do
	@afundingline.funder=nil
	@afundingline.should_not be_valid
	end
 it "should not have a blank interest_rate" do
	@afundingline.interest_rate=nil
        @afundingline.should_not be_valid
 end
 it "should not have a blank disbursal_date" do
	@afundingline.disbursal_date=nil
	@afundingline.should_not be_valid
 end
 it "should not have a blank amount" do
	@afundingline.amount=nil
	@afundingline.should_not be_valid	
 end
 it "should not have blank last payment date" do
	@afundingline.last_payment_date= nil
        @afundingline.should_not be_valid
 end
 
 it "should have first payment done before last payment" do
 	@afundingline.last_payment_date="2006-03-03"
	@afundingline.should_not be_valid
 end
 it "should be disbursed before first payment" do
 	@afundingline.disbursal_date="2008-05-05"
	@afundingline.should_not be_valid
	
 end

end
