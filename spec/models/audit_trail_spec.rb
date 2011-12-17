require File.join( File.dirname(__FILE__), '..', "spec_helper" )

#
# These tests are currently failing because AuditTrails require a user, which
# DataAccessObserver takes from the current session. Of course there is no session
# while runnnig these specs.
#
describe AuditTrail do 
  before(:all) do
    AuditTrail.all.destroy
  end

  it "should create history for branch creation" do
    lambda {
      branch = Factory(:branch, :name => "Kerela branch", :code => "branch")
      branch.should be_valid
    }.should change(AuditTrail, :count).by(1)
  end

  it "should create history for branch update" do
    lambda {
      # We'll update the branch created in the first test
      branch = Branch.all(:name => 'Kerela branch').first
      branch.name = "Kerela branch 1"
      branch.save
      branch.should be_valid
    }.should change(AuditTrail, :count).by(1)
  end

  it "should create history for center creation" do
    lambda {
      center = Factory( :center, :name => "Kerela branch", :code => "branch")
      center.should be_valid
    }.should change(AuditTrail, :count).by(1)
  end

  it "should create history for center update" do
    lambda {
      # We'll update the center from the previous test
      center = Center.all(:name => 'Kerela branch').first
      center.name = "kerala center"
      center.save
      center.should be_valid
    }.should change(AuditTrail, :count).by(1)

    trail = AuditTrail.last.changes.reduce({}){|s, x| s+=x}
    trail.should == {:name=>["Kerela branch", "kerala center"]}
  end

  it "should create history for client creation" do
    lambda {
      client = Factory(:client, :name => 'Ms C.L. Ient', :reference => 'XW000-2009.01.05', :date_joined => Date.parse('2000-01-01'))
      client.should be_valid
    }.should change(AuditTrail, :count).by(1)
  end

  it "should create history for client update" do
    lambda {
      client = Client.all(:name => 'Ms C.L. Ient').first
      client.name = "Ms. C.L. Inet 1"
      client.save
      client.should be_valid
    }.should change(AuditTrail, :count).by(1)

    trail = AuditTrail.last.changes.reduce({}){|s, x| s+=x}
    trail.should == {:name => ["Ms C.L. Ient", "Ms. C.L. Inet 1"]}
  end

  it "should create history for loan creation" do
    lambda {
      loan = Factory(:loan, :amount => 1000, :interest_rate => 0.2, :installment_frequency => :weekly,
        :number_of_installments => 25, :scheduled_first_payment_date => "2000-12-06", :applied_on => "2000-02-01",
        :scheduled_disbursal_date => "2000-06-13")
      loan.should be_valid
      loan.history_disabled = true
    }.should change(AuditTrail, :count).by(1)
  end

  it "should record approval of loan" do
    manager = Factory(:staff_member)

    lambda {
      loan = Loan.all(:scheduled_disbursal_date => '2000-06-13').first
      loan.history_disabled = true
      loan.approved_on = "2000-02-03"
      loan.approved_by = manager
      loan.disbursal_date = loan.scheduled_disbursal_date
      loan.disbursed_by = manager
      loan.save
    }.should change(AuditTrail, :count).by(1)

    trail = AuditTrail.last.changes.reduce({}){|s, x| s+=x}
    trail[:disbursal_date].should == [nil, Date.new(2000, 06, 13)]
    trail[:approved_by_staff_id].should == [nil, 1]
    trail[:disbursed_by_staff_id].should == [nil, 1]
    trail[:approved_on].should == [nil, Date.new(2000, 02, 03)]
  end
end
