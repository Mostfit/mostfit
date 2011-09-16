require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe ModelObserver do

  before(:all) do
    @date = Date.new(2009, 6, 29)
    @weekdays = [:monday,:tuesday,:wednesday,:thursday,:friday,:saturday,:sunday]
    @user = User.new(:login => 'Joe', :password => 'password', :password_confirmation => 'password', :role => :admin)
    @user.save
    @user.should be_valid
    @manager = StaffMember.new(:name => "Mrs. M.A. Nerger")
    @manager.should be_valid
    @manager.save
    @funder = Funder.new(:name => "FWWB")
    @funder.save
    @funder.should be_valid
    @funding_line = FundingLine.new(:amount => 10_000_000, :interest_rate => 0.15, :purpose => "for women", :disbursal_date => "2006-02-02", 
                                    :first_payment_date => "2007-05-05", :last_payment_date => "2009-03-03")
    @funding_line.funder = @funder
    @funding_line.save
    @funding_line.should be_valid
    # @target_for_number = Target.new(:attached_to => :staff_member, :target_of => :client_registration, :attached_id => @manager.id, :start_value => 100, :target_type => :relative,
    #                                 :target_value => 1000, :created_at => Date.today, :start_date => Date.new(Date.today.year, Date.today.month, 01),
    #                                 :deadline => Date.new(Date.today.year, Date.today.month, -1))
    # @target_for_number.save
    # @target_for_number.errors.each {|e| puts e}
    # @target_for_number.should be_valid

    # @target_for_amount = Target.new(:attached_to => :staff_member, :target_of => :loan_disbursement_by_amount, :attached_id => @manager.id, :target_type => :relative,
    #                                 :target_value => 10_00_000, :created_at => Date.today, :start_value => 10_000,
    #                                 :start_date => Date.new(Date.today.year, Date.today.month, 01),
    #                                 :deadline => Date.new(Date.today.year, Date.today.month, -1))
    # @target_for_amount.save!
    # @target_for_amount.errors.each {|e| puts e}
    # @target_for_amount.should be_valid

    @organization = Organization.new(:name => "Organization", :org_guid => "63416690-b6c1-012e-8195-002170a9c469")
    @organization.save
    @organization.should be_valid
    
    @accounting_period = AccountingPeriod.new(:name => "Organization", :begin_date => (@date - 100), :end_date => (Date.today + 100), :organization_id => Organization.first.id)
    @accounting_period.save!


    @region = Region.new(:id => 1, :name => "Region 1", :manager_id => @manager.id, :creation_date => Date.today)
    @region.save
    @region.errors.each {|e| puts e}
    @region.should be_valid

    @area = Area.new(:name => "Area 1", :region_id => @region.id, :manager_id => @manager.id, :creation_date => Date.today)
    @area.save
    @area.errors.each {|e| puts e}
    @area.should be_valid
    
    @fee = Fee.new(:name => "Processing Fee 3 %", :percentage => 0.03, :payable_on => :loan_approved_on)
    @fee.save
    @fee.errors.each{|e| puts e}
    @fee.should be_valid
    
    @staff_member = StaffMember.new(:name => 'Bhagubhai Dholakia')
    @staff_member.save
    @staff_member.errors.each{|e| puts e}
    @staff_member.should be_valid


    @branch = Branch.new(:name => "Bhavnagar")
    @branch.manager = @manager
    @branch.code = "BVN"
    @branch.save
    @branch.errors.each {|e| puts e}
    @branch.should be_valid

    @center = Center.new(:name => "Munnar hill center")
    @center.manager = @manager
    @center.branch = @branch
    @center.creation_date = @date + 30
    @center.meeting_day = :monday
    @center.code = "center"
    @center.save
    @center.errors.each{|e| puts e}
    @center.should be_valid
    
    @client_type = ClientType.new(:type => 'Standard Client')
    @client_type.save
    @client_type.errors.each{|e| puts e}
    @client_type.should be_valid
  end
  
  # Creation tests
  it "should create an entry in the model event log when a client is created" do
    @client = Client.new(:name => 'HetalBen', :reference => 'GJ046921', :created_by_user_id => @user.id, :created_by_staff_member_id => @staff_member.id, :center => @center, :date_joined => (@date + 60), :client_type_id => @client_type.id )
    @client.save
    @client.errors.each{|e| puts e}
    @client.should be_valid
    
    log = ModelEventLog.last
    log.event_change.should == :create
    #log.event_changed_at.should == DateTime.now
    log.event_on_type.should == @client.class.to_s.downcase.to_sym   
    log.event_on_id.should == @client.id    
    log.event_on_name.should == @client.name
    log.event_accounting_action.should == :allow_posting
    log.event_accounting_action_effective_date.should == nil    
  end

  it "should create an entry in the model event log when a loan product is created" do
    @loan_product = LoanProduct.new
    @loan_product.name = "LP1"
    @loan_product.max_amount = 10000
    @loan_product.min_amount = 1000
    @loan_product.max_interest_rate = 100
    @loan_product.min_interest_rate = 0.1
    @loan_product.installment_frequency = :weekly
    @loan_product.max_number_of_installments = 50
    @loan_product.min_number_of_installments = 25
    @loan_product.loan_type = "DefaultLoan"
    @loan_product.valid_from = Date.parse('2000-01-01')
    @loan_product.valid_upto = Date.parse('2012-01-01')
    @loan_product.save
    @loan_product.errors.each {|e| puts e}
    @loan_product.should be_valid
        
    log = ModelEventLog.last
    log.event_change.should == :create
    #log.event_changed_at.should == DateTime.now
    log.event_on_type.should == @loan_product.class.to_s.downcase.to_sym   
    log.event_on_id.should == @loan_product.id    
    log.event_on_name.should == @loan_product.name
    log.event_accounting_action.should == :allow_posting
    log.event_accounting_action_effective_date.should == nil    
  end
  
  it "should create an entry in the model event log when a loan is created" do
    @loan = Loan.new(:amount => 10000, :interest_rate => 1, :installment_frequency => :weekly, :number_of_installments => 25, 
                    :scheduled_first_payment_date => "2009-12-06", :applied_on => "2009-02-01", :scheduled_disbursal_date => "2009-03-13")
    @loan.history_disabled = false
    @loan.discriminator = DefaultLoan
    @loan.applied_by       = @manager
    @loan.funding_line     = @funding_line
    @loan.client           = @client
    @loan.loan_product     = @loan_product
    debugger
    # @loan.valid?
    @loan.errors.each {|e| puts e}
    # @loan.should be_valid
    @loan.approved_on = "2009-02-03"
    @loan.approved_by = @manager
    @loan.save
    # @loan.should be_valid
        
    log = ModelEventLog.last
    log.event_change.should == :create
    #log.event_changed_at.should == DateTime.now
    log.event_on_type.should == @loan.class.superclass   
    log.event_on_id.should == @client.id    
    log.event_on_name.should == @client.name
    log.event_accounting_action.should == :allow_posting
    log.event_accounting_action_effective_date.should == nil    
  end

## Updation tests
  it "should create an entry in the model event log when a client is updated" do
  end

  it "should create an entry in the model event log when a loan product is updated" do
  end

  it "should create an entry in the model event log when a loan is updated" do
  end


## Deletion tests
  it "should create an entry in the model event log when a client is deleted" do
  end

  it "should create an entry in the model event log when a loan product is deleted" do
  end

  it "should create an entry in the model event log when a loan is deleted" do
  end

end
