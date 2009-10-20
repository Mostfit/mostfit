require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe LoanProduct do

  before(:each) do
    @loan_product = LoanProduct.new(:name => "Test product", :min_amount => 100, :max_amount => 10000, :min_interest_rate => 8, :max_interest_rate => 10, 
                                    :valid_from => Date.today, :valid_upto => Date.today, :installment_frequency => :weekly)
    @loan_product.should be_valid
  end
  it "should not be valid without min amount" do
    @loan_product.min_amount=nil
    @loan_product.should_not be_valid
  end
  it "should not be valid without max amount" do
    @loan_product.max_amount=nil
    @loan_product.should_not be_valid
  end
  it "should not be valid with min amount greater than max amount" do
    @loan_product.max_amount = 1000
    @loan_product.min_amount = 10000    
    @loan_product.should_not be_valid
  end

  it "should not be valid without min interest rate" do
    @loan_product.min_interest_rate=nil
    @loan_product.should_not be_valid
  end
  it "should not be valid without max amount" do
    @loan_product.max_interest_rate=nil
    @loan_product.should_not be_valid
  end
  it "should not be valid with min amount greater than max amount" do
    @loan_product.max_interest_rate = 10
    @loan_product.min_interest_rate = 12    
    @loan_product.should_not be_valid
  end

  it "should not be valid without valid from date" do
    @loan_product.valid_from=nil
    @loan_product.should_not be_valid
  end
  it "should not be valid without valid upto dtae" do
    @loan_product.valid_upto=nil
    @loan_product.should_not be_valid
  end
  it "should not be valid with min amount greater than max amount" do
    @loan_product.valid_from = Date.today
    @loan_product.valid_upto = Date.today-10    
    @loan_product.should_not be_valid
  end
end
