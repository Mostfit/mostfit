require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Fee do
  before(:all) do
    Payment.all.destroy! if Payment.all.count > 0
    Client.all.destroy! if Client.count > 0
    @user = User.new(:login => 'Joey', :password => 'password', :password_confirmation => 'password')
    @user.role = :admin
    @user.save
    @user.should be_valid

    @manager = StaffMember.new(:name => "Mrs. M.A. Nerger")
    @manager.save
    @manager.should be_valid

    @funder = Funder.new(:name => "FWWB")
    @funder.save
    @funder.should be_valid

    @funding_line = FundingLine.new(:amount => 10_000_000, :interest_rate => 0.15, :purpose => "for women", :disbursal_date => "2006-02-02", :first_payment_date => "2007-05-05", :last_payment_date => "2009-03-03")
    @funding_line.funder = @funder
    @funding_line.save
    @funding_line.should be_valid

    @branch = Branch.new(:name => "Kerela branch")
    @branch.manager = @manager
    @branch.code = "BR"
    @branch.save
    @branch.should be_valid

    @center = Center.new(:name => "Munnar hill center")
    @center.manager = @manager
    @center.branch  = @branch
    @center.code = "CE"
    @center.creation_date = Date.parse('2006-01-01')
    @center.save
    @center.errors.each {|e| puts e}
    @center.should be_valid

    @client = Client.new(:name => 'Ms C.L. Ient', :reference => Time.now.to_s, :created_by => @user, 
                         :date_joined => Date.parse('2006-01-01'), :created_by_staff => @center.manager,
                         :client_type => ClientType.create(:type => "Standard"), :center => @center)
    @client.save
    @client.errors.each {|e| puts e}
    @client.should be_valid
    # validation needs to check for uniqueness, therefor calls the db, therefor we dont do it
    @loan_product = LoanProduct.new
    @loan_product.name = "LP1"
    @loan_product.max_amount = 2000
    @loan_product.min_amount = 1000
    @loan_product.max_interest_rate = 100
    @loan_product.min_interest_rate = 0.1
    @loan_product.installment_frequency = :weekly
    @loan_product.max_number_of_installments = 25
    @loan_product.min_number_of_installments = 25
    @loan_product.loan_type = "DefaultLoan"
    @loan_product.valid_from = Date.parse('2000-01-01')
    @loan_product.valid_upto = Date.parse('2012-01-01')
    @loan_product.save
    @loan_product.errors.each {|e| puts e}
    @loan_product.should be_valid
  end

  before :each do
    ApplicableFee.all.destroy!
    Loan.all.destroy!
    Fee.all.destroy!
    @loan = Loan.new(:amount => 1000, :interest_rate => 0.2, :installment_frequency => :weekly, :number_of_installments => 25, :scheduled_first_payment_date => "2000-12-06", :applied_on => "2000-02-01", :scheduled_disbursal_date => "2000-06-13")
    @loan.history_disabled = true
    @loan.applied_by       = @manager
    @loan.funding_line     = @funding_line
    @loan.client           = @client
    @loan.loan_product     = @loan_product
    @loan.valid?
    @loan.errors.each {|e| puts e}
    @loan.should be_valid
    @loan.save
    @f = Fee.new
    @f.name = "Test Fee"
    @f.payable_on = :loan_applied_on
    @f.amount = 1000
    @f.should be_valid
    @f.amount = nil
  end

  it "should have a name" do
    @f.name = nil
    @f.should_not be_valid
  end

  it "should have either an amount or a percentage" do
    @f.amount = @f.percentage = nil
    @f.should_not be_valid
    @f.amount = 1000
    @f.should be_valid
    @f.errors.each {|e| puts e}
    @f.amount = nil
    @f.percentage = 0
    @f.should be_valid
  end

  it "should never return less than min_amount" do
    @f.min_amount = 1000
    @f.fees_for(@loan).should == 1000
  end

  it "should never return more than max_amount" do
    @f.percentage = 1
    @f.max_amount = 1
    @f.fees_for(@loan).should == 1
  end

## start of loan fee spec
  it "should return correct fee_schedule for loan" do
    @f.percentage = 0.1
    @loan_product.fees = [@f]
    @loan_product.save
    @loan.save
    @loan.fee_schedule.should == {@loan.applied_on => {@f => 100}}

    @f2 = Fee.new(:name => "Other Fee")
    @f2.amount = 111
    @f2.payable_on = :loan_scheduled_first_payment_date
    @f2.save.should be_true
    @loan.fee_schedule.should == {@loan.applied_on => {@f => 100}}
    
    @loan_product.fees << @f2
    @loan_product.save
    @loan.save
    # the fees have already been levied so this should not change
    @loan.fee_schedule.should == {@loan.applied_on => {@f => 100}}

    @loan.levy_fees(false)
    @loan.fee_schedule.should == {@loan.applied_on => {@f => 100}, @loan.scheduled_first_payment_date => {@f2 => 111}}
  end

  it "should change when loan details change" do
    @f.amount = 100
    @f.payable_on = :loan_disbursal_date
    @loan_product.fees = [@f]
    @loan_product.save
    @loan.save
    @loan.fee_schedule.should == {Date.new(2000,6,13) => {@f => 100}}
    @loan.scheduled_disbursal_date = Date.new(2000,6,15)
    @loan.valid?
    @loan.errors.each{|e| puts e}
    @loan.should be_valid
    @loan.save.should == true
    @loan.fee_schedule.should == {Date.new(2000,6,15) => {@f => 100}}
  end

it "should change when loan amount changes" do
    @f.percentage = 0.1
    @loan_product.fees = [@f]
    @loan_product.save
    @loan.levy_fees
    @loan.fee_schedule.should == {@loan.applied_on => {@f => 100}}
    @loan.amount = 1100
    @loan.save
    @loan.fee_schedule.should == {@loan.applied_on => {@f => 110}}
  end

  it "should return correct fee_schedule for disbursal / scheduled_disbursal_date" do
    @f = Fee.new
    @f.name = "Disbursal Fee"
    @f.payable_on = :loan_disbursal_date
    @f.amount = 1000
    @f.should be_valid
    @loan_product.fees = [@f]
    @loan_product.save
    @loan.levy_fees

    @loan.fee_schedule.should == {@loan.scheduled_disbursal_date => {@f => 1000}}

    @loan.disbursal_date = @loan.scheduled_disbursal_date + 10
    @loan.levy_fees

    @loan.fee_schedule.should == {(@loan.scheduled_disbursal_date  + 10)=> {@f => 1000}}
  end
  
  it "should return correct fee_schedule for multiple fees even on the same date" do
    @f2 = Fee.new(:name => "Other Fee")
    @f2.amount = 111
    @f2.payable_on = :loan_applied_on
    @f2.save.should be_true
    @f.percentage = 0.1
    @f.save
    @loan_product.fees = [@f, @f2]
    @loan.applicable_fees.destroy!
    @loan.levy_fees
    @loan.fee_schedule.should == {@loan.applied_on => {@f => 100, @f2 => 111}}
  end

  it "should not change when loan product changes" do
    @f.amount = 100
    @loan_product.fees = [@f]
    @loan_product.save
    @loan.save
    @loan.fee_schedule.should == {@loan.applied_on => {@f => 100}}
    @f2 = Fee.new(:name => "Other Fee")
    @f2.amount = 111
    @f2.payable_on = :loan_applied_on
    @f2.save.should be_true
    @loan_product.fees = [@f2]
    @loan_product.save
    @loan.disbursal_date = Date.today
    @loan.save
    @loan.fee_schedule.should == {@loan.applied_on => {@f => 100}}
  end


  it "should change only the loan details if the loan product changes between saves" do
    # setup the fees
    @f.amount = 100
    @f.payable_on = :loan_disbursal_date
    @loan_product.fees = [@f]
    @loan_product.save
    @loan.save
    @loan.fee_schedule.should == {Date.new(2000,6,13) => {@f => 100}}
    @f.amount = 10000
    @f.save
    @loan.approved_on = Date.new(2001,06,30)
    @loan.approved_by = StaffMember.first
    @loan.disbursal_date = Date.new(2001,07,01)
    @loan.disbursed_by = StaffMember.first
    @loan.save
    @loan.fee_schedule.should == {Date.new(2001,7,1) => {@f => 100}} #should have the same amount as before
    @f2 = Fee.new(:name => "Other Fee")
    @f2.amount = 111
    @f2.payable_on = :loan_applied_on
    @f2.save.should be_true
    @loan_product.fees = [@f2]
    @loan_product.save
    @loan.disbursal_date = Date.new(2001,07,01)
    @loan.save
    @loan.fee_schedule.should == {Date.new(2001,7,1) => {@f => 100}} # should have same amount and fee as before
  end
    

  it "should return correct fees payable" do
    @f2 = Fee.new(:name => "Other Fee")
    @f2.amount = 111
    @f2.payable_on = :loan_applied_on
    @f2.should be_valid
    @f.percentage = 0.1
    @loan_product.fees = [@f, @f2]
    @loan_product.save
    @loan.save #calls levy fees automatically
    @loan.fee_schedule[@loan.applied_on].should  == {@f => 100, @f2 => 111}
    @loan.fees_payable_on.should == {@f => 100, @f2 => 111}
  end


  it "should return correct fees_paid" do
    @f2 = Fee.new(:name => "Other Fee")
    @f2.amount = 111
    @f2.payable_on = :loan_applied_on
    @f2.should be_valid
    @f2.save
    @f.percentage = 0.1
    @f.save
    @loan_product.fees = []
    @loan_product.fees << @f
    @loan_product.fees << @f2
    @loan_product.save
    @loan.save
    
    dd = @loan.applied_on
    @loan.fees_payable_on(dd - 1).should be_empty
    @loan.fees_payable_on.should == {@f => 100, @f2 => 111}
    @loan.fees_payable_on(dd + 1).should == {@f => 100, @f2 => 111}

    @loan.fees_paid.should == {}

    @p = Payment.new(:amount => 20, :received_on => '2009-01-01', :type => :fees, :client => @client, :fee => @f,
                     :received_by => @manager, :created_by => @user, :loan => @loan, :comment => "test fee")
    @p.valid?
    @p.errors.each {|e| puts e}
    @p.should be_valid
    @p.save.should be_true

    @loan.fees_paid.should == {Date.parse('2009-01-01') => {@f => 20}}
    @loan.fees_payable_on.should == {@f => 80, @f2 => 111}
    @loan.total_fees_payable_on.should == 111 + 100 - 20
    @loan.total_fees_due.should == 111 + 100 - 20

    @p = Payment.new(:amount => 20, :received_on => '2009-01-01', :type => :fees, :client => @client,
                     :received_by => @manager, :created_by => @user, :loan => @loan, :fee => @f2)
    @p.save.should be_true
    @loan.total_fees_payable_on.should == 111 + 100 - 40
    @loan.fees_paid.should == {Date.parse('2009-01-01') => {@f => 20, @f2 => 20}}
    @loan.fees_payable_on.should == {@f => 80, @f2 => 91}
    Payment.all.destroy!
  end

  it "should give correct fees overdue" do
    @f.amount = 100
    @f.payable_on = :loan_disbursal_date
    @loan_product.fees = [@f]
    @loan_product.save
    @loan.save
    @loan.fee_schedule.should == {Date.new(2000,6,13) => {@f => 100}}
    @loan.disbursal_date = @loan.scheduled_disbursal_date + 1
    @loan.save
  end

  it "should repay correctly" do
    @f.amount = 100
    @f.payable_on = :loan_disbursal_date
    @f2 = Fee.new(:name => "Other Fee")
    @f2.amount = 111
    @f2.payable_on = :loan_applied_on
    @loan_product.fees = [@f, @f2]
    @loan_product.save

    @loan.save.should be_true
    @loan.applicable_fees.count.should == 2    
    @loan.fees_payable_on(@loan.applied_on).should == {@f2 => 111}
    
    @loan.fees_payable_on(@loan.scheduled_disbursal_date).should == {@f2 => 111, @f => 100}
    @loan.disbursal_date = @loan.scheduled_disbursal_date
    @loan.disbursed_by = @loan.applied_by
    success, @fees = @loan.pay_fees(105, @loan.disbursal_date, @manager, User.first)
    success.should == true

    @loan.disbursal_date = nil
    @loan.disbursed_by = nil
    @loan.save
  end
 ### end of loan fee spec

### start of client fee spec

  it "should give correct fee schedule for client" do
    @client_fee = Fee.new(:name => "client fee", :amount => 20, :payable_on => :client_date_joined)
    @client_fee.client_types << ClientType.first
    @client_fee.save
    @client_fee.errors.each {|e| puts e}
    @client_fee.should be_valid
    @client.save

    @client.fee_schedule.should == {@client.date_joined => {@client_fee => 20}}
    @client.fees_payable_on.should == {@client_fee => 20}
    @client.fees_payable_on(@client.date_joined - 1).should == {}

    old_dues =  @client.total_fees_due(@client.date_joined - 1)
    @client.total_fees_payable_on(@client.date_joined - 1).should == old_dues
    @client.total_fees_payable_on(@client.date_joined).should == 20 + old_dues
    @client.fees_payable_on.should == {@client_fee => 20}

    @p = Payment.new(:amount => 10, :received_on => @client.date_joined - 1, :type => :fees, :client => @client,
                     :received_by => @manager, :created_by => @user, :comment => "client fee")
    @p.valid?
    @p.should_not be_valid # trying to pay fee before it is due

    @p = Payment.new(:amount => 10, :received_on => @client.date_joined, :type => :fees, :client => @client,
                     :received_by => @manager, :created_by => @user, :comment => "client fee")
    @p.save
    @p.errors.each {|e| puts e}
    @p.should be_valid
    @client.fees_paid.should == {@client.date_joined => {@client_fee => 10}}
    @client.fees_payable_on.should == {@client_fee => 10}
  end

  it "should work just as well for another fee" do
    Payment.all(:client => @client, :loan => nil).destroy!
    ct = ClientType.create(:type => "New")
    @fee1 = Fee.new(:name => "card fee", :amount => 20, :payable_on => :client_date_joined)
    @fee1.errors.each {|e| puts e}
    @fee1.client_types << ct
    @fee1.save
    @fee1.should be_valid

    @fee2 = Fee.new(:name => "grt fee", :amount => 10, :payable_on => :client_grt_pass_date)
    @fee2.errors.each {|e| puts e}
    @fee2.client_types << ct
    @fee2.save
    @fee2.should be_valid

    @client = Client.new(:name => 'Ramesh bhai', :reference => "foo132431", :created_by => @user, :date_joined => Date.parse('2006-01-01'),
                         :client_type => ct, :center => @center, :grt_pass_date => Date.today)
    @client.save

    @client.fee_schedule.should == {@client.date_joined => {@fee1 => 20}, Date.today => {@fee2 => 10}}
    @client.total_fees_payable_on(Date.today - 1).should == 20
    @client.total_fees_payable_on(Date.today).should == 30
    @client.fees_payable_on.should == {@fee1 => 20, @fee2 => 10}
    @p = Payment.new(:amount => 20, :received_on => @client.date_joined, :type => :fees, :client => @client,
                     :received_by => @manager, :created_by => @user, :comment => "card fee")
    @p.should be_valid 
    @p.save
    @p = Payment.new(:amount => 5, :received_on => Date.today - 1, :type => :fees, :client => @client,
                     :received_by => @manager, :created_by => @user, :comment => "grt fee")
    @p.should_not be_valid # trying to pay fee before it is due
    @p.received_on = Date.today
    @p.should be_valid
    @p.save
    @client.fees_paid.should == {@client.date_joined => {@fee1 => 20}, Date.today => {@fee2 => 5}}
    @client.fees_payable_on.should == {@fee2 => 5}

  end

  it "should pay client fees correctly" do
    Payment.all.destroy!
    Fee.all.destroy!
    @client = Client.get(@client.id)
    @fee1 = Fee.new(:name => "client fee", :amount => 20, :payable_on => :client_date_joined)
    @fee1.client_types << @client.client_type
    @fee1.save

    @fee2 = Fee.new(:name => "grt fee", :amount => 10, :payable_on => :client_grt_pass_date)
    @fee2.client_types << @client.client_type
    @fee2.save
    
    @client.applicable_fees.destroy!
    @client.should be_valid
    @client.save
    @client.fees_payable_on.should == {@fee1 => 20}
    @client.pay_fees(5, Date.today - 1, @manager, @user)
    @client.fees_payable_on.should == {@fee1 => 20 - 5}
    
    @client.grt_pass_date = Date.today - 20
    @client.save!
    @client.levy_fees
    @client.fees_payable_on.should == {@fee1 => 20 - 5, @fee2 => 10}
  end


### client fees
end
