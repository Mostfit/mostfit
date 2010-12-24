require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe StockRegister do

  before(:all) do
    StaffMember.all.destroy!
    @manager = StaffMember.new(:name => "Mr. Ram Turanai")
    @manager.save
    @manager.errors
    @manager.should be_valid
  end

  before(:all) do
    Branch.all.destroy!
    @branch = Branch.new(:name => "Kanpur")
    @branch.manager = @manager
    @branch.code = "branch1"
    @branch.save
    @branch.errors.each {|e| p e}
    @branch.should be_valid
  end

  before(:each) do
    StockRegister.all.destroy!
    @stock_register = StockRegister.new
    @stock_register.branch = @branch
    @stock_register.stock_code = "CHR123"
    @stock_register.stock_name = "Chair"
    @stock_register.stock_quantity = 30
    @stock_register.bill_number = 6754328
    @stock_register.bill_date = '20-12-2010'
    @stock_register.date_of_entry = '24-12-2010'
    @stock_register.manager = @manager
    @stock_register.save
    @stock_register.errors {|e| p e}
    @stock_register.should be_valid
  end

  it "should not be valid without a person entering the details" do
    @stock_register.manager = nil
    @stock_register.should_not be_valid
  end

  it "should belong to a particular branch" do
    @stock_register.branch = @branch
    @stock_register.should be_valid
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
