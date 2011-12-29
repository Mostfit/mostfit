require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe StockRegister do
  before(:each) do
    StockRegister.all.destroy!
    @stock_register = Factory(:stock_register)
    @stock_register.should be_valid
  end

  it "should not be valid without a person entering the details" do
    @stock_register.manager = nil
    @stock_register.should_not be_valid
  end

  it "should belong to a particular branch" do
    @stock_register.branch = nil
    @stock_register.should_not be_valid
  end

  it "should not be valid without stock code" do
    @stock_register.stock_code = nil
    @stock_register.should_not be_valid
  end

  it "should not be valid without bill number of stock" do
    @stock_register.bill_number = nil
    @stock_register.should_not be_valid
  end

  it "should not be valid without bill date of stock" do
    @stock_register.bill_date = nil
    @stock_register.should_not be_valid
  end

  it "should not be valid without the entry date" do
    @stock_register.date_of_entry = nil
    @stock_register.should_not be_valid
  end

  it "should not be valid without a branch" do
    @stock_register.branch = nil
    @stock_register.should_not be_valid
  end

end
