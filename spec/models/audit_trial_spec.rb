require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe AuditTrail do 
  before(:all) do
    load_fixtures :users, :staff_members, :loan_products, :funders, :funding_lines, :client_types
    @manager = StaffMember.first
    @user    = User.first
  end

  it "should create history for branch creation" do
    old_count = AuditTrail.count
    @branch = Branch.new(:name => "Kerela branch", :manager => @manager, :code => "branch")
    @branch.save.should be_true
    @branch.errors.each {|e| p e}
    @branch.should be_valid
    (AuditTrail.count - old_count).should == 1
  end

  it "should create history for branch update" do
    old_count = AuditTrail.count
    @branch = Branch.first
    @branch.name = "Kerela branch 1"
    @branch.save.should be_true
    @branch.errors.each {|e| p e}
    @branch.should be_valid
    (AuditTrail.count - old_count).should == 1
  end

  it "should create history for center creation" do
    old_count = AuditTrail.count
    @center = Center.new(:name => "Kerela branch", :manager => @manager, :code => "branch", :branch => Branch.first)
    @center.save
    @center.errors.each {|e| p e}
    @center.should be_valid
    (AuditTrail.count - old_count).should == 1
  end

  it "should create history for center updation" do
    old_count = AuditTrail.count
    @center = Center.first
    @center.name = "kerala center"
    @center.save
    @center.errors.each {|e| p e}
    @center.should be_valid
    (AuditTrail.count - old_count).should == 1
    trail = AuditTrail.last.changes.reduce({}){|s, x| s+=x}
    trail.should == {:name=>["Kerela branch", "kerala center"]}
  end

  it "should create history for client creation" do
    old_count = AuditTrail.count
    @client = Client.new(:name => 'Ms C.L. Ient', :reference => 'XW000-2009.01.05', :date_joined => Date.parse('2000-01-01'), 
                         :client_type => ClientType.first, :created_by => @user, :center => Center.first)
    @client.save
    @client.errors.each{|e| puts e}
    @client.should be_valid
    (AuditTrail.count - old_count).should == 1
  end

  it "should create history for client update" do
    old_count = AuditTrail.count
    @client = Client.first
    @client.name = "Ms. C.L. Inet 1"
    @client.save
    @client.errors.each{|e| puts e}
    @client.should be_valid
    (AuditTrail.count - old_count).should == 1
    trail = AuditTrail.last.changes.reduce({}){|s, x| s+=x}
    trail.should == {:name => ["Ms C.L. Ient", "Ms. C.L. Inet 1"]}
  end

  it "should create history for loan creation" do
    old_count = AuditTrail.count
    @loan = Loan.new(:amount => 1000, :interest_rate => 0.2, :installment_frequency => :weekly, :number_of_installments => 25, :applied_by => @manager,
                     :scheduled_first_payment_date => "2000-12-06", :applied_on => "2000-02-01", :scheduled_disbursal_date => "2000-06-13", 
                     :funding_line => FundingLine.first, :client => Client.first, :loan_product => LoanProduct.first)
    @loan.should be_valid
    @loan.history_disabled = true
    @loan.save
    (AuditTrail.count - old_count).should == 1
  end

  it "should record approval of loan" do
    old_count = AuditTrail.count
    @loan = Loan.first
    @loan.history_disabled = true
    @loan.approved_on = "2000-02-03"
    @loan.approved_by = @manager
    @loan.disbursal_date = @loan.scheduled_disbursal_date
    @loan.disbursed_by = @manager
    @loan.save
    (AuditTrail.count - old_count).should == 1
    trail = AuditTrail.last.changes.reduce({}){|s, x| s+=x}
    trail[:disbursal_date].should == [nil, Date.new(2000, 06, 13)]
    trail[:approved_by_staff_id].should == [nil, 1]
    trail[:disbursed_by_staff_id].should == [nil, 1]
    trail[:approved_on].should == [nil, Date.new(2000, 02, 03)]
  end
end
