require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Funder do
  before(:each) do
  @funder=Funder.new(:id=>10,:name=>"sparsh")
  @funder.should be_valid
  
  end
  it "should not be valid without having a name" do
 	@funder.name=nil
	@funder.should_not be_valid
  end
  it "should be able to have funding lines" do
	@fundingline1= FundingLine.new(:amount => 10_000_00, :interest_rate => 0.15, :purpose => "for 			     women",:disbursal_date=>"2002-02-02", :first_payment_date => "2007-05-05", :last_payment_date => 			     "2009-03-03")
	@fundingline1.funder=@funder
	@fundingline1.should be_valid
	@funder.should be_valid
	@fundingline2= FundingLine.new(:amount => 10_000, :interest_rate => 0.15, :purpose => "for women", :disbursal_date 		=>"2002-02-02", :first_payment_date => "2007-05-05", :last_payment_date => "2009-03-03")
	@fundingline2.funder=@funder
  	@fundingline2.should be_valid
	@funder.should be_valid
	
end
  it "should give correct count of completed lines " do
	@funder.completed_lines.should==0
	@funder.should be_valid
	fundingline3= FundingLine.new(:amount => 10_000, :interest_rate => 0.15, :purpose => "for women", :disbursal_date 		=>"2002-02-02", :first_payment_date => "2007-05-05", :last_payment_date => "2009-03-03")
	fundingline3.funder=@funder
	fundingline3.should be_valid
	fundingline3.save
	@funder.completed_lines.should==1
	@funder.destroy
	fundingline3.destroy
  end
  it "should give correct count of active lines" do
  	fundingline4= FundingLine.new(:amount => 10_000, :interest_rate => 0.15, :purpose => "for women", 
	:disbursal_date=>"2002-02-02", :first_payment_date => "2007-05-05", :last_payment_date => "2009-03-03")
	fundingline5= FundingLine.new(:amount => 10_000, :interest_rate => 0.15, :purpose => "for women", 
	:disbursal_date =>"2002-02-02", :first_payment_date => "2007-05-05", :last_payment_date => "2009-03-03")
	fundingline4.funder=@funder
	fundingline5.funder=@funder
	fundingline4.save
	fundingline5.save
	@funder.active_lines.should==2
	@funder.destroy
	FundingLine.all.destroy!
  end
  it "should give correct count of total lines " do
  	 fundingline6= FundingLine.new(:amount => 10_000_000, :interest_rate => 0.15, :purpose => "for women", 
	:disbursal_date	=>"2012-02-02", :first_payment_date => "2012-05-05", :last_payment_date => "2012-08-03")
	 fundingline7= FundingLine.new(:amount => 10_000_000, :interest_rate => 0.15, :purpose => "for women", 
	:disbursal_date=>"2012-02-02", :first_payment_date => "2012-05-05", :last_payment_date => "2012-08-03")
	fundingline6.funder=@funder
	fundingline7.funder=@funder
	fundingline6.save
	fundingline7.save
	@funder.total_lines("2009-02-02").should==2
  end

end
