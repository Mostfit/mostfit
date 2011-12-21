require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe InsuranceCompany do

  it "should not allow duplicate names" do
    i1 = Factory(:insurance_company, :name => "foo")
    i1.should be_valid
    i2 = Factory.build(:insurance_company, :name => "foo")
    i2.should_not be_valid
  end

end
