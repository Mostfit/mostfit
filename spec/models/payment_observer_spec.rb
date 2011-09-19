require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe PaymentObserver do

  before(:all) do
    ParRow = Struct.new(:less_than_30, :between_30_and_60, :between_60_and_90, :more_than_90)
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
    @num_clients = []
    @loans = []

    @fee = Fee.new(:name => "Processing Fee 3 %", :percentage => 0.03, :payable_on => :loan_approved_on)
    @fee.save
    @fee.errors.each{|e| puts e}
    @fee.should be_valid

    @organization = Organization.new(:name => "Organization", :org_guid => "63416690-b6c1-012e-8195-002170a9c469")
    @organization.save
    @organization.should be_valid
    
    @accounting_period = AccountingPeriod.new(:name => "Organization", :begin_date => (@date - 100), :end_date => (Date.today + 100), :organization_id => Organization.first.id)
    @accounting_period.save!
    
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
    @loan_product.fees = [@fee]
    @loan_product.save
    @loan_product.errors.each {|e| puts e}
    @loan_product.should be_valid

    @target_for_number = Target.new(:attached_to => :staff_member, :target_of => :client_registration, :attached_id => @manager.id, :start_value => 100, :target_type => :relative,
                                    :target_value => 1000, :created_at => Date.today, :start_date => Date.new(Date.today.year, Date.today.month, 01),
                                    :deadline => Date.new(Date.today.year, Date.today.month, -1))
    @target_for_number.save
    @target_for_number.errors.each {|e| puts e}
    @target_for_number.should be_valid

    @target_for_amount = Target.new(:attached_to => :staff_member, :target_of => :loan_disbursement_by_amount, :attached_id => @manager.id, :target_type => :relative,
                                    :target_value => 10_00_000, :created_at => Date.today, :start_value => 10_000,
                                    :start_date => Date.new(Date.today.year, Date.today.month, 01),
                                    :deadline => Date.new(Date.today.year, Date.today.month, -1))
    @target_for_amount.save!
    @target_for_amount.errors.each {|e| puts e}
    @target_for_amount.should be_valid

    @region = Region.new(:id => 1, :name => "Region 1", :manager_id => @manager.id, :creation_date => Date.today)
    @region.save
    @region.errors.each {|e| puts e}
    @region.should be_valid

    @area = Area.new(:name => "Area 1", :region_id => @region.id, :manager_id => @manager.id, :creation_date => Date.today)
    @area.save
    @area.errors.each {|e| puts e}
    @area.should be_valid
    
    # generate a couple of branches
    if Loan.all.count == 0
      Merb.logger.info "Generating data"
      ["br1","br2"].each do |b|
        Merb.logger.info "\t generating branch"
        branch = instance_variable_set("@#{b}",Branch.new(:name => b))
        branch.manager = @manager
        branch.area_id = @area.id
        branch.code = b
        branch.save
        branch.should be_valid
        # and seven centres in each, one for each day
        [:monday, :tuesday].each_with_index do |day,cwday|                               
          center = instance_variable_set("@#{b}_#{day}",Center.new(:name => day.to_s))
          center.manager = @manager
          center.branch = branch
          center.meeting_day = day
          center.code = day
          center.save
          center.errors.each {|e| puts e}
          center.should be_valid
          # make three clients
          num_clients = 3
          # give each one a loan of amount between 10K and 20K in multiples of 10
          (1..num_clients).each do |cl|
            Merb.logger.info "#{b}_#{day}_#{cl}"
            client = instance_variable_set("@#{b}_#{day}_#{cl}", Client.new(:name => 'Ms C.L. Ient', :reference => "#{b}_#{day}_#{cl}"))
            client.center  = center
            client.created_by = @user
            client.client_type = ClientType.first||ClientType.create(:type => "standard")
            client.date_joined = @date - 1
            client.save
            client.errors.each {|e| puts e}
            client.should be_valid
            loan = instance_variable_set("@#{b}_#{day}_#{cl}_l", Loan.new)
            loan.amount = cl * 1000 # loans total in each branch is (7*8)/2 * 1000 = 28,000
            # how should they be disbursed? randomly? something more elegant? 1 in each week?
            # which is the first day?
            # next meeting day of course
            loan.scheduled_disbursal_date = @date+cwday
            loan.disbursal_date = loan.scheduled_disbursal_date
            loan.disbursed_by = @manager
            loan.scheduled_first_payment_date = loan.scheduled_disbursal_date + 7
            loan.interest_rate = 0.1
            loan.installment_frequency = :weekly
            loan.number_of_installments = 50
            loan.applied_on = @date
            loan.applied_by = @manager
            loan.approved_on = loan.applied_on
            loan.approved_by = @manager
            loan.funding_line = @funding_line
            loan.client = client
            loan.loan_product = @loan_product
            loan.history_disabled = true
            loan.save
            loan.errors.each  {|e| puts e}
            loan.should be_valid
          end
        end
      end
    end
    Loan.all.each{|l| l.update_history}
  end
  
  it "should create an entry in transaction log when a new payment is created" do
    loan = Loan.first
    loan.repay(20, @user, "2009-07-06", @manager)
    payment = Payment.last
    client_name = payment.client ? payment.client.name : nil
    center = payment.client && payment.client.center ? payment.client.center : nil
    center_id = center ? center.id : nil
    center_name = center ? center.name : nil
    
    staff_member = payment.received_by_staff_id ? StaffMember.get(payment.received_by_staff_id) : nil
    staff_member_name = staff_member ? staff_member.name : nil
    #fee_name = payment.fee ? payment.fee.name : nil

    transactions = TransactionLog.all(:txn_guid => payment.guid)
    transactions.count.should == 1
    transaction = transactions[0]
    transaction.txn_guid.should == payment.guid
    #transaction.update_type.should == action
    transaction.txn_type.should == :receipt
    transaction.nature_of_transaction.should == "#{payment.type}_received".to_sym
    transaction.sub_type_id.should == payment.fee_id
    transaction.sub_type_name.should == (payment.fee_id ? Fee.get(payment.fee_id).name : nil)
    transaction.amount.should == payment.amount
    transaction.currency.should == :INR
    transaction.effective_date.should == payment.received_on
    transaction.record_date.should == payment.created_at
    transaction.updated_at_time.should == nil
    transaction.verified_at_time.should == nil
    transaction.deleted_at_time.should == nil
    transaction.paid_by_type.should == :client
    transaction.paid_by_id.should == payment.client_id
    transaction.paid_by_name.should == client_name
    transaction.received_by_type.should == :staff_member
    transaction.received_by_id.should == payment.received_by_staff_id
    transaction.received_by_name.should == staff_member_name
    transaction.transacted_at_type.should == :center
    transaction.transacted_at_id.should == center_id
    transaction.transacted_at_name.should == center_name
    extended_info = payment.extended_info
    if transaction.extended_info_items
      transaction.extended_info_items.each_with_index do |item, idx|
        item[:item_type].should == extended_info[idx][:item_type]
        item[:item_id].should == extended_info[idx][:item_id]
        item[:item_value].should == extended_info[idx][:item_value]
      end
    end
  end

  it "should create two entries (one deletion and one creation) when a payment is edited" do
    # payment = Payment.last
    # payment 
  end

  it "should create one entry in transaction log when a payment is deleted" do
    # payment = Payment.last
    # payment = Payment.destroy
    # transactions = TransactionLog.all(:txn_guid => payment.guid)
    # transactions.count.should == 1
    # transaction = transactions[0]
    # transaction.txn_guid.should == payment.guid
    # #transaction.update_type.should == action
    # transaction.type.should == :receipt
    # transaction.nature_of_transaction.should == "#{payment.type}_received".to_sym
    # transaction.sub_type_id.should == payment.fee_id
    # transaction.sub_type_name.should == (payment.fee_id ? Fee.get(payment.fee_id).name : nil)
    # transaction.amount.should == payment.amount
    # transaction.currency.should == :INR
    # transaction.effective_date.should == payment.received_on
    # transaction.record_date.should == payment.created_at
    # transaction.updated_at_time.should == nil
    # transaction.verifed_at_time.should == nil
    # transaction.deleted_at_time.should == nil
    # transaction.paid_by_type.should == :client
    # transaction.paid_by_id.should == payment.client_id
    # transaction.paid_by_name.should == client_name
    # transaction.received_by_type.should == :staff_member
    # transaction.received_by_id.should == payment.received_by_staff_id
    # transaction.received_by_name.should == staff_member_name
    # transaction.transacted_at_type.should == :center
    # transaction.transacted_at_id.should == center_id
    # transaction.transacted_at_name.should == center_name
  end
end
