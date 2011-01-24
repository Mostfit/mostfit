require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Grt do
  before(:all) do
    load_fixtures :staff_members, :branches, :centers    
  end

  it "should have at least one client group to be valid" do
    grt  = Grt.new(:date => Date.today, :status => 'Passed')
    grt.should_not be_valid
    
    cg = ClientGroup.create(:name => "group 1", :code => "grp1", :created_by_staff => StaffMember.first, :center => Center.first)
    grt.client_group = cg
    grt.should be_valid
  end
    
end
