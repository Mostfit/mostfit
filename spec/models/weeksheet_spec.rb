require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Weeksheet do
  before(:all) do
    load_fixtures :users, :staff_members, :regions, :areas, :branches, :centers, :client_types, :clients, :loan_products, :funders, :funding_lines, :loans, :loan_history
  end

  before(:each) do
    @center = Center.get(1)
    @weeksheets = Weeksheet.get_center_weeksheet(@center, Date::civil(2011,03,22))
  end

  it "should be get center weeksheet" do
    @weeksheets.first.should_not == nil
    @weeksheets.first.weeksheet.center_id.should == @center.id
  end

  it "should be equal to given date" do
    @weeksheets.first.weeksheet.date.should == Date::civil(2011,03,22)
  end

  it "Installment number should be befor given date" do
    @loan = Loan.get(1)
    installment_number = @loan.number_of_installments_before(Date::civil(2011,03,22))    
    @weeksheets.first.installment.should == installment_number
  end

  it "should be equal to given center_id" do
    @weeksheets.first.weeksheet.center_id.should == @center.id
  end

  it "should not get center weeksheet if center not paying on given date" do
    @weeksheets = Weeksheet.get_center_weeksheet(@center, Date::civil(2011,03,21))
    @weeksheets.first.weeksheet_id.should == nil
  end

end
