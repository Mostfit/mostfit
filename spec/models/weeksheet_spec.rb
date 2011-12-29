require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Weeksheet do
  before(:all) do
    @client = Factory(:client)
    @center = @client.center
  end

  before(:each) do
    @weeksheet_rows = Weeksheet.get_center_weeksheet(@center, Date::civil(2011,03,22))
  end

  it "should be get center weeksheet" do
    @weeksheet_rows.first.should_not eql(nil)
    @weeksheet_rows.first.weeksheet.center_id.should eql(@center.id)
  end

  it "should be equal to given date" do
    @weeksheet_rows.first.weeksheet.date.should == Date::civil(2011,03,22)
  end

  it "Installment number should be before given date" do
    loan = Factory(:disbursed_loan, :client => @client)
    installment_number = loan.number_of_installments_before(Date::civil(2011,03,22))    
    @weeksheet_rows.first.installment.should == installment_number
  end

  it "should not get center weeksheet if center not paying on given date" do
    @weeksheet_rows = Weeksheet.get_center_weeksheet(@center, Date::civil(2011,03,21))
    @weeksheet_rows.first.weeksheet_id.should == nil
  end

end
