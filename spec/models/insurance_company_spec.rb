require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe InsuranceCompany do

  it "should not allow duplicate names" do
    i1 = InsuranceCompany.create(:name => "foo")
    i2 = InsuranceCompany.new(:name => "foo")
    i2.should_not be_valid
  end

end
