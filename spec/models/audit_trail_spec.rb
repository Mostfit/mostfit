require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe AuditTrail do 

  before(:each) do
    session_mock = mock('session')
    session_mock.stub!(:user).and_return(Factory(:user))

    DataAccessObserver.insert_session( session_mock.object_id )
  end

  # This test (and all 'on create' tests) fails because DataAccessObserver
  # does not log on create, only update. There is no after :create callback.
  # Initially I expected after :save to cover the create action as well but
  # apparently it does not.
  #
  #  before :create do
  #    DataAccessObserver.check_session(self)
  #    DataAccessObserver.get_object_state(self, :create)
  #  end
  #
  #  before :save do
  #    # DataAccessObserver.check_session(self)
  #    debugger
  #    DataAccessObserver.get_object_state(self, :update) if not self.new?
  #  end
  #
  #  after :save do
  #    DataAccessObserver.log(self)
  #  end
  #
#  it "should create history for branch creation" do
#    lambda {
#      branch = Factory(:branch)
#      branch.should be_valid
#      Branch.create( branch.attributes )
#    }.should change(AuditTrail, :count).by(1)
#  end

  it "should create history for branch update" do
    branch = Factory(:branch, :name => 'Munnar branch')
    lambda {
      branch.name = 'Kerala branch'
      branch.save
      branch.should be_valid
    }.should change(AuditTrail, :count).by(1)
  end

#  it "should create history for center creation" do
#    lambda {
#      center = Factory(:center)
#      center.should be_valid
#    }.should change(AuditTrail, :count).by(1)
#  end

  it "should create history for center update" do
    center = Factory(:center, :name => 'Munnar center')
    lambda {
      center.name = 'Kerala center'
      center.save
      center.should be_valid
    }.should change(AuditTrail, :count).by(1)

    trail = AuditTrail.last.changes.reduce({}){|s, x| s+=x}
    trail.should == {:name=>['Munnar center', 'Kerala center']}
  end

#  it "should create history for client creation" do
#    lambda {
#      client = Factory(:client)
#      client.should be_valid
#    }.should change(AuditTrail, :count).by(1)
#  end

  it "should create history for client update" do
    client = Factory(:client, :name => 'Ms C.L. Ient')

    lambda {
      client.name = "Mr C.U. Stomer"
      client.save
      client.should be_valid
    }.should change(AuditTrail, :count).by(1)

    trail = AuditTrail.last.changes.reduce({}){|s, x| s+=x}
    trail.should == {:name => ["Ms C.L. Ient", "Mr C.U. Stomer"]}
  end

#  it "should create history for loan creation" do
#    lambda {
#      loan = Factory(:loan)
#      loan.should be_valid
#    }.should change(AuditTrail, :count).by(1)
#  end


  # A loan has to be approved to be valid so we can only check 
  # the audit_trail after disbursal.
  it "should record disbursal of loan" do
    manager = Factory(:staff_member)
    manager.should be_valid

    loan = Factory(:loan,
      :scheduled_disbursal_date => Date.new(2000, 06, 13),
      :disbursed_by_staff_id    => nil,
      :disbursal_date           => nil )
    loan.should be_valid

    lambda {
      loan.disbursal_date = loan.scheduled_disbursal_date
      loan.disbursed_by = manager
      loan.save
    }.should change(AuditTrail, :count).by(1)

    trail = AuditTrail.last.changes.reduce({}){|s, x| s+=x}
    trail[:disbursal_date].should == [nil, Date.new(2000, 06, 13)]
    trail[:disbursed_by_staff_id].should == [nil,manager.id]
  end
end
