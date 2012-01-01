require File.join( File.dirname(__FILE__), '..', "spec_helper" )

#
# Most of these tests are currently meaningless because the validations for
# AccountingPeriod are borked, meaning new accounting_periods are never valid.
# The problem is described in the model on #closing_done_sequentially
#
describe AccountingPeriod do

  before(:each) do
    @valid_accounting_period = Factory.build(:accounting_period)
  end

  it "should be valid with default attributes" do
    @valid_accounting_period.should be_valid
  end

  it "should have a name" do
    @valid_accounting_period.name = nil
    @valid_accounting_period.should_not be_valid
  end

  it "should have a begin date" do
    @valid_accounting_period.begin_date = nil
    @valid_accounting_period.should_not be_valid
  end

  it "should have an end date" do
    @valid_accounting_period.end_date = nil
    @valid_accounting_period.should_not be_valid
  end
  
  it "should not overlap with any other accounting period" do
    new_accounting_period = Factory.build(:accounting_period, @valid_accounting_period.attributes)
    new_accounting_period.should_not be_valid
  end

end
