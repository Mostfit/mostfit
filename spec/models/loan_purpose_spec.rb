require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe LoanPurpose do

  it "should not have duplicate purposes with same name" do
    p1 = LoanPurpose.new(:value => "foo", :code => "foo")
    p1.should be_valid
    p1.save

    p2 = LoanPurpose.new(:value => "foo", :code => "foo")
    p2.should_not be_valid
  end

end
