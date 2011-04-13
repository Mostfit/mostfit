require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe AccountingPeriod do
  before(:all) do
    @accounting_period = AccountingPeriod.create(:name => "Q1 2011", :begin_date => Date.new(2011, 04, 01), 
                                                 :end_date => Date.new(2011, 06, 30))
    
  end
  
  it "should have a name" do
    @accounting_period.name = nil
    @accounting_period.should_not be_valid
  end

  it "should have a begin date" do
    @accounting_period.begin_date = nil
    @accounting_period.should_not be_valid
  end

  it "should have an end date" do
    @accounting_period.end_date = nil
    @accounting_period.should_not be_valid
  end
  
  it "should not overlap with any other accounting period" do
    ap = AccountingPeriod.new(@accounting_period.attributes)
    ap.should_not be_valid
  end

end
