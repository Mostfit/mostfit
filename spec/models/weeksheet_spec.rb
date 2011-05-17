require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Weeksheet do
  before(:all) do
    load_fixtures :users, :staff_members, :regions, :areas, :branches, :centers, :client_types, :clients, :loan_products, :funders, :funding_lines, :loans, :loan_history
  end

  before(:each) do
    @center = Center.get(1)
    @weeksheets = Weeksheet.get_center_sheet(@center, Date::civil(2011,03,22))
  end

  it "should be get center weeksheet" do
    @weeksheets.first.should_not == nil
    @weeksheets.first.center_id.should == @center.id
  end

  it "should be equal to given date" do
    @weeksheets.first.date.should == Date::civil(2011,03,22)
  end

  it "total due should be equal principal+intrest+fee" do
    total_due = @weeksheets.first.principal.to_f + @weeksheets.first.interest.to_f + @weeksheets.first.fee.to_f
    @weeksheets.first.total_due.to_f.should == total_due
  end

  it "Installment number should be befor given date" do
    @loan = Loan.get(1)
    installment_number = @loan.number_of_installments_before(Date::civil(2011,03,22))    
    @weeksheets.first.installment_number.should == installment_number
  end

  it "should be equal to given center_id" do
    @weeksheets.first.center_id.should == @center.id
  end

  it "should get staff_member weeksheet" do
  end

  it "should not get center weeksheet if center not paying on given date" do
    @weeksheets = Weeksheet.get_center_sheet(@center, Date::civil(2011,03,21))
    @weeksheets.first.should == nil
  end

  it "should not get staff_member weeksheet if not any center paying on given date" do
  end

end
