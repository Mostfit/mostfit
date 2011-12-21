require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Grt do

  it "should have at least one client group to be valid" do
    grt = Factory.build(:grt, :date => Date.today, :status => 'Passed', :client_group => nil)
    grt.should_not be_valid
    
    cg = Factory(:client_group, :name => "group 1", :code => "grp1")
    grt.client_group = cg
    grt.should be_valid
  end
    
end
