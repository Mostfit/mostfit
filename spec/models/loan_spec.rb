require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Loan do

  before(:all) do
    @user = Factory(:user)
    @user.should be_valid

    @manager = Factory(:staff_member)
    @manager.should be_valid

    @funding_line = Factory(:funding_line)
    @funding_line.should be_valid

    @branch = Factory(:branch, :manager => @manager)
    @branch.should be_valid

    @center = Factory(:center, :manager => @manager, :branch => @branch, :meeting_day => :wednesday)
    @center.should be_valid

    @client = Factory(:client, :center => @center, :created_by_user_id => @user.id)
    @client.should be_valid

    @equated_weekly = RepaymentStyle.new(:style => "EquatedWeekly", :round_total_to => 1, :round_interest_to => 1)
    @equated_weekly.save

    @flat = RepaymentStyle.new(:style => "Flat")
    @flat.save

    @loan_product = LoanProduct.new
    @loan_product.name = "LP1"
    @loan_product.max_amount = 10000
    @loan_product.min_amount = 1000
    @loan_product.max_interest_rate = 100
    @loan_product.min_interest_rate = 0.1
    @loan_product.installment_frequency = :weekly
    @loan_product.max_number_of_installments = 25
    @loan_product.min_number_of_installments = 12
    @loan_product.repayment_style = @flat
    @loan_product.valid_from = Date.parse('2000-01-01')
    @loan_product.valid_upto = Date.parse('2012-01-01')
    @loan_product.save
    @loan_product.errors.each {|e| puts e}
    @loan_product.should be_valid
  end

  before(:each) do
    @loan_product.loan_validation_methods = nil
    @loan_product.save

    @loan = Factory(:loan,
      :amount => 1000, :interest_rate => 0.2, :installment_frequency => :weekly, :number_of_installments => 25,
      :scheduled_first_payment_date => "2000-12-06", :applied_on => "2000-02-01", :scheduled_disbursal_date => "2000-06-13",
      :applied_by => @manager, :funding_line => @funding_line, :client => @client, :loan_product => @loan_product)
    @loan.discriminator = Loan
    @loan.should be_valid
    @loan.approved_on = "2000-02-03"
    @loan.approved_by = @manager
    @loan.should be_valid
  end
  
  it "should have a discrimintator" do
    @loan.discriminator.should_not be_blank
  end

  it "should not be valid without belonging to a client" do
    @loan.client = nil
    @loan.should_not be_valid
  end

  it "should give error if amount is blank" do
    @loan.amount = nil
    @loan.should_not be_valid
  end

  it "should not be valid without being approved properly" do
    @loan.applied_by = nil
    @loan.should_not be_valid
    @loan.applied_by = @manager
    @loan.applied_on = nil
    @loan.should_not be_valid
  end

  it "should not be valid without being validated properly" do
    @loan.disbursal_date = @loan.scheduled_disbursal_date
    @loan.disbursed_by = @manager
    @loan.should be_valid
    @loan.validated_on = @loan.disbursal_date
    @loan.validated_by = @manager
    @loan.should be_valid
    @loan.validated_on = nil
    @loan.should_not be_valid
    @loan.validated_on = @loan.disbursal_date
    @loan.validated_by = nil
    @loan.should_not be_valid
  end
  it "should not be valid without being rejected properly" do
    date = @loan.approved_on
    @loan.approved_by = nil
    @loan.approved_on = nil
    @loan.should be_valid
    @loan.rejected_on = date
    @loan.rejected_by = nil
    @loan.should_not be_valid
    @loan.rejected_by = @manager
    @loan.rejected_on = nil
    @loan.should_not be_valid
  end
  it "should not be valid without belonging to a client" do
    @loan.client = nil
    @loan.should_not be_valid
  end
  it "should not be valid without a proper amount" do
    @loan.amount_applied_for = nil
    @loan.amount = nil
    @loan.should_not be_valid
    @loan.amount = -1
    @loan.should_not be_valid
    @loan.amount = 0
    @loan.should_not be_valid
  end
  it "should take the amount from the loan product if the loan product can give one" do
    @loan_product.max_amount = @loan_product.min_amount = 10000
    @loan.amount = nil
    @loan.should be_valid
    @loan.amount.should == 10000
  end


  it "should not be valid without a proper interest_rate" do
    @loan.interest_rate = nil
    @loan.should_not be_valid
    @loan.interest_rate = -1
    @loan.should_not be_valid
    @loan.interest_rate = -0.2
    @loan.should_not be_valid
    @loan.interest_rate = 0.1
    @loan.should be_valid
  end
  it "should take the interest rate from the loan product if the loan product can give one" do
    @loan_product.max_interest_rate = @loan_product.min_interest_rate = 20
    @loan.interest_rate = nil
    @loan.should be_valid
    @loan.interest_rate.should == 0.2
  end



  it "should be valid with a proper installment_frequency" do
    @loan.installment_frequency = :daily
    @loan.should be_valid
    @loan.installment_frequency = :weekly
    @loan.should be_valid
    @loan.installment_frequency = :monthly
    @loan.should be_valid
  end
  it "should not be valid without proper installment_frequency" do
    @loan_product.installment_frequency = nil
    @loan.loan_product = @loan_product
    @loan.installment_frequency = nil
    @loan.should_not be_valid
    @loan.installment_frequency = 'day'
    @loan.should_not be_valid
    @loan.installment_frequency = :month
    @loan.should_not be_valid
    @loan.installment_frequency = :week
    @loan.should_not be_valid
    @loan.installment_frequency = 'month'
    @loan.should_not be_valid
    @loan.installment_frequency = 7
    @loan.should_not be_valid
    @loan.installment_frequency = 14
    @loan.should_not be_valid
    @loan.installment_frequency = 30
    @loan.should_not be_valid
    @loan_product.installment_frequency = :weekly
  end
  it "should not be valid without a proper number_of_installments" do
    @loan.number_of_installments = nil
    @loan.should_not be_valid
    @loan.number_of_installments = -1
    @loan.should_not be_valid
    @loan.number_of_installments = -0
    @loan.should_not be_valid
  end
  it "should not be valid without a scheduled_first_payment_date" do
    @loan.scheduled_first_payment_date = nil
    @loan.should_not be_valid
  end
  it "should not be valid without a scheduled_disbursal_date" do
    @loan.scheduled_disbursal_date = nil
    @loan.should_not be_valid
  end
  it "should not be valid with a disbursal date earlier than the loan is approved" do
    @loan.disbursed_by = @manager
    @loan.disbursed_by = @manager
    @loan.disbursal_date = @loan.approved_on - 10
    @loan.should_not be_valid
    @loan.disbursal_date = @loan.approved_on
    @loan.should be_valid
    @loan.disbursal_date = @loan.approved_on + 10
    @loan.should be_valid
  end
  it "should not be valid when validated_on is earlier than the disbursal_date" do
    @loan.disbursed_by   = @manager
    @loan.disbursal_date = @loan.scheduled_disbursal_date
    @loan.validated_on   = @loan.disbursal_date
    @loan.validated_by   = @manager
    @loan.should be_valid
    @loan.validated_on   = @loan.disbursal_date + 1
    @loan.should be_valid
    @loan.validated_on   = @loan.disbursal_date - 1
    @loan.should_not be_valid
  end
  it "should not be valid when written_off_on is earlier than the disbursal_date" do
    @loan.written_off_by = @manager
    @loan.disbursed_by   = @manager
    @loan.disbursal_date = @loan.scheduled_disbursal_date
    @loan.written_off_on = @loan.disbursal_date
    @loan.should be_valid
    @loan.written_off_on = @loan.disbursal_date + 1
    @loan.should be_valid
    @loan.written_off_on = @loan.disbursal_date - 1
    @loan.should_not be_valid
  end
  it "should not be valid without approved_on earlier than scheduled_disbursal_date" do
    @loan.scheduled_disbursal_date = @loan.approved_on - 10
    @loan.should_not be_valid
    @loan.scheduled_disbursal_date = @loan.approved_on
    @loan.should be_valid
    @loan.scheduled_disbursal_date = @loan.approved_on + 10
    @loan.should be_valid
  end
  it "should not be valid without being properly written off" do
    @loan.disbursal_date = @loan.scheduled_disbursal_date
    @loan.disbursed_by   = @manager
    @loan.written_off_on = @loan.disbursal_date
    @loan.written_off_by = @manager
    @loan.should be_valid
    @loan.written_off_on = @loan.disbursal_date
    @loan.written_off_by = nil
    @loan.should_not be_valid
    @loan.written_off_on = nil
    @loan.written_off_by = @manager
    @loan.should_not be_valid
  end
  it "should not be valid without being properly disbursed" do
    @loan.disbursal_date = @loan.scheduled_disbursal_date
    @loan.disbursed_by   = @manager
    @loan.should be_valid
    @loan.disbursal_date = nil
    @loan.disbursed_by   = @manager
    @loan.should_not be_valid
    @loan.disbursal_date = @loan.scheduled_disbursal_date
    @loan.disbursed_by   = nil
    @loan.should_not be_valid
  end
  it "should not be valid when scheduled_first_payment_date if before scheduled_disbursal_date" do
    @loan.scheduled_first_payment_date = @loan.scheduled_disbursal_date + 1
    @loan.should be_valid
    @loan.scheduled_first_payment_date = @loan.scheduled_disbursal_date
    @loan.should be_valid
    @loan.scheduled_first_payment_date = @loan.scheduled_disbursal_date - 1  # before disbursed
    @loan.should_not be_valid
  end
  it "should not be valid if scheduled disbursal date and scheduled first payment date are not center meeting dates" do
#     @loan.scheduled_disbursal_date = @center.meeting_day
#     @loan.should be_valid
#     @loan.scheduled_first_payment_date = @center.meeting_day
#     @loan.should be_valid
#     @loan.scheduled_disbursal_date = @center.meeting_day + 1
#     @loan.should_not be_valid
#     @loan.scheduled_disbursal_date = @center.meeting_day - 1
#     @loan.should_not be_valid
#     @loan.scheduled_first_payment_date = @center.meeting_day + 1
#     @loan.should_not be_valid
#     @loan.scheduled_first_payment_date = @center.meeting_day - 1
#     @loan.should_not be_valid
  end
  
  it "should not be valid if repayment dates are not center meeting dates" do
    @loan.scheduled_disbursal_date = Date.new(2000, 11, 30)
    @loan.should be_valid

    @loan.scheduled_disbursal_date = Date.new(2000, 11, 29)
    @loan.should be_valid

    @loan.disbursal_date = Date.new(2000, 11, 23)
    @loan.applied_by     = @manager
    @loan.disbursed_by   = @manager
    @loan.valid?
    @loan.errors.each {|e| puts e}
    @loan.should be_valid

    @loan.disbursal_date = Date.new(2000, 12, 29)
    @loan.should be_valid

    @loan.disbursal_date = Date.new(2000, 12, 30)
    @loan.should be_valid

    @loan_product.loan_validation_methods = "disbursal_dates_must_be_center_meeting_days"
    @loan_product.save

    @center.meeting_day_for(Date.new(2000, 11, 29)).should == :wednesday
    @loan.scheduled_disbursal_date = Date.new(2000, 11, 29)
    @loan.disbursal_date = nil
    @loan.disbursed_by   = nil
    @loan.valid?
    @loan.errors.each {|e| puts e}
    @loan.should be_valid

    @loan.disbursal_date = Date.new(2000, 11, 30)
    @loan.disbursed_by   = @manager
    @loan.valid?
    @loan.should_not be_valid

    @loan.disbursal_date = Date.new(2000, 11, 02)
    @loan.disbursed_by   = @manager
    @loan.valid?
    @loan.should_not be_valid

    @loan.disbursal_date = Date.new(2000, 11, 27)
    @loan.disbursed_by   = @manager
    @loan.should_not be_valid

    @loan.disbursal_date = Date.new(2000, 11, 22)
    @loan.disbursed_by   = @manager    
    @loan.should be_valid

#     @loan.scheduled_first_payment_date = @loan.scheduled_first_payment_date + 1
#     @loan.should_not be_valid
#     @loan.scheduled_first_payment_date = @loan.scheduled_first_payment_date - 1
    #     @loan.should_not be_valid
  end

  it ".shift_date_by_installments should shift dates properly, even odd ones.. and backwards." do
    loan = Loan.new(:installment_frequency => :daily)
    loan.shift_date_by_installments(Date.parse('2001-01-01'), 1).should == Date.parse('2001-01-02')
    loan.shift_date_by_installments(Date.parse('2001-01-01'), -1).should == Date.parse('2000-12-31')
    loan.shift_date_by_installments(Date.parse('2001-12-31'), 1).should == Date.parse('2002-01-01')
    loan = Loan.new(:installment_frequency => :weekly)
    loan.shift_date_by_installments(Date.parse('2001-01-01'), 1).should == Date.parse('2001-01-08')
    loan.shift_date_by_installments(Date.parse('2001-01-01'), -1).should == Date.parse('2000-12-25')
    loan.shift_date_by_installments(Date.parse('2012-12-21'), 4).should == Date.parse('2013-01-18')
    loan.shift_date_by_installments(Date.parse('2001-01-01'),-52).should == Date.parse('2000-01-03')
    loan = Loan.new(:installment_frequency => :biweekly)
    loan.shift_date_by_installments(Date.parse('2001-01-01'), 1).should == Date.parse('2001-01-15')
    loan.shift_date_by_installments(Date.parse('2001-01-01'), -1).should == Date.parse('2000-12-18')
    loan = Loan.new(:installment_frequency => :monthly)
    loan.shift_date_by_installments(Date.parse('2001-01-01'), 1).should == Date.parse('2001-02-01')
    loan.shift_date_by_installments(Date.parse('2001-01-01'), -1).should == Date.parse('2000-12-01')
    loan.shift_date_by_installments(Date.parse('2000-01-31'), 1).should == Date.parse('2000-02-29') # febs last days:
    loan.shift_date_by_installments(Date.parse('2000-01-30'), 1).should == Date.parse('2000-02-29')
    loan.shift_date_by_installments(Date.parse('2000-01-29'), 1).should == Date.parse('2000-02-29')
    loan.shift_date_by_installments(Date.parse('2000-03-31'), -1).should == Date.parse('2000-02-29')
    loan.shift_date_by_installments(Date.parse('2000-03-30'), -1).should == Date.parse('2000-02-29')
    loan.shift_date_by_installments(Date.parse('2000-03-29'), -1).should == Date.parse('2000-02-29')
    loan.shift_date_by_installments(Date.parse('2001-01-31'), 1).should == Date.parse('2001-02-28')
    loan.shift_date_by_installments(Date.parse('2001-01-30'), 1).should == Date.parse('2001-02-28')
    loan.shift_date_by_installments(Date.parse('2001-01-29'), 1).should == Date.parse('2001-02-28')
    loan.shift_date_by_installments(Date.parse('2001-01-28'), 1).should == Date.parse('2001-02-28')
    loan.shift_date_by_installments(Date.parse('2001-03-31'), -1).should == Date.parse('2001-02-28')
    loan.shift_date_by_installments(Date.parse('2001-03-30'), -1).should == Date.parse('2001-02-28')
    loan.shift_date_by_installments(Date.parse('2001-03-29'), -1).should == Date.parse('2001-02-28')
    loan.shift_date_by_installments(Date.parse('2001-03-28'), -1).should == Date.parse('2001-02-28')
  end


  it ".number_of_installments_before should do what it promises" do
    loan = Loan.new(:installment_frequency => :daily, :scheduled_first_payment_date => Date.parse('2001-01-01'), :number_of_installments => 10)
    loan.number_of_installments_before(Date.parse('2001-01-01')).should == 1
    loan.number_of_installments_before(Date.parse('2001-01-02')).should == 2
    loan.number_of_installments_before(Date.parse('2001-01-03')).should == 3
    loan.number_of_installments_before(Date.parse('2000-12-31')).should == 0
    loan.number_of_installments_before(Date.parse('1999-01-01')).should == 0
    loan.number_of_installments_before(Date.parse('2001-01-10')).should == 10
    loan.number_of_installments_before(Date.parse('2001-01-11')).should == 10
    loan.installment_frequency = :weekly
    loan.number_of_installments_before(Date.parse('2001-01-01')).should == 1
    loan.number_of_installments_before(Date.parse('2001-01-02')).should == 1
    loan.number_of_installments_before(Date.parse('2001-01-08')).should == 2
    loan.number_of_installments_before(Date.parse('2001-01-01')+(7*10)).should == 10
    loan.number_of_installments_before(Date.parse('2001-01-01')+(7*10)+1).should == 10
    loan.number_of_installments_before(Date.parse('2001-01-01')+(7*10)+100).should == 10
    loan.number_of_installments_before(Date.parse('1999-01-01')).should == 0
    loan.installment_frequency = :biweekly
    loan.number_of_installments_before(Date.parse('2001-01-01')).should == 1
    loan.number_of_installments_before(Date.parse('2001-01-14')).should == 1
    loan.number_of_installments_before(Date.parse('2001-01-15')).should == 2
    loan.number_of_installments_before(Date.parse('2001-01-01')+10*14).should == 10
    loan.number_of_installments_before(Date.parse('2001-01-01')+100*14).should == 10
    loan.number_of_installments_before(Date.parse('1999-01-01')).should == 0
    loan.installment_frequency = :monthly
    loan.number_of_installments_before(Date.parse('2001-01-01')).should == 1
    loan.number_of_installments_before(Date.parse('2001-02-01')).should == 2
    loan.number_of_installments_before(Date.parse('2001-03-01')).should == 3
    loan.number_of_installments_before(Date.parse('2001-10-01')).should == 10
    loan.number_of_installments_before(Date.parse('2001-11-01')).should == 10
    loan.scheduled_first_payment_date = Date.parse('2000-01-30')  # febs last days
    loan.number_of_installments_before(Date.parse('2000-02-01')).should == 1
    loan.number_of_installments_before(Date.parse('2000-02-28')).should == 1
    loan.number_of_installments_before(Date.parse('2000-02-29')).should == 1
    loan.number_of_installments_before(Date.parse('2000-03-01')).should == 2
    loan.number_of_installments_before(Date.parse('2000-03-30')).should == 3
    loan.scheduled_first_payment_date = Date.parse('2001-01-30')  # febs last days (non leap year)
    loan.number_of_installments_before(Date.parse('2001-02-28')).should == 1
    loan.number_of_installments_before(Date.parse('2001-03-01')).should == 2
    loan.number_of_installments_before(Date.parse('2001-03-30')).should == 3
  end

  it ".last_loan_history_date should have some tests -- albeit more a view thing" do
    (@loan.scheduled_first_payment_date + (@loan.number_of_installments - 1) * @loan.installment_frequency_in_days).should == @loan.payment_schedule.keys.max
  end

  it ".scheduled_repaid_on give the proper date" do
    @loan.scheduled_repaid_on.should eql(Date.parse('2001-05-23'))
  end
  it "should have proper values for principal, interest and total to be received" do
    @loan.total_interest_to_be_received.should == 1000 * 0.2
    @loan.total_to_be_received.should == 1000 * (1.2)
  end

  it ".status should give status accoring to changing properties up to it written off" do
    @loan.status.should == :approved
    @loan.disbursal_date = @loan.scheduled_disbursal_date
    @loan.disbursed_by   = @manager
    @loan.save
    @loan.status.should == :outstanding
    @loan.status(@loan.disbursal_date - 1).should == :approved
    @loan.written_off_on = @loan.scheduled_first_payment_date
    @loan.written_off_by = @manager
    @loan.status.should == :written_off
    @loan.status(@loan.scheduled_first_payment_date - 1).should == :outstanding
  end
  it ".status should give status accoring to changing properties up to it is repaid" do
    @loan.disbursal_date = @loan.scheduled_disbursal_date
    @loan.disbursed_by   = @manager
    @loan.status.should == :outstanding
    lambda{@loan.repay(@loan.total_to_be_received, @user, Date.today, @manager)}.should raise_error

    @loan.save
    @loan.history_disabled=false
    @loan.update_history
    # no payments on unsaved (new_record? == true) loans:
    @loan.save.should == true
    r = @loan.repay(@loan.total_to_be_received, @user, Date.today, @manager)
    r[0].should == true
    @loan.status.should == :repaid
    @loan.status(@loan.scheduled_disbursal_date - 1).should == :approved
  end
  it ".status should give status accoring to changing properties before being approved" do
    @loan.status(@loan.applied_on - 1).should == :applied_in_future
    @loan.status(@loan.applied_on).should == :applied
    @loan.status(@loan.approved_on - 1).should == :applied
    @loan.status.should == :approved
  end
  it ".status should give status accoring to changing properties when being rejected" do
    date = @loan.approved_on
    @loan.approved_on = nil
    @loan.approved_by = nil
    @loan.rejected_on = date
    @loan.rejected_by = @manager
    @loan.should be_valid
    @loan.status(@loan.rejected_on - 1).should == :applied
    @loan.status(@loan.rejected_on).should == :rejected
    @loan.status.should == :rejected
  end


  it "cannot repay an unsaved loan" do
    lambda { @loan.repay(@loan.total_to_be_received, @user, Date.today, @manager) }.should raise_error
  end

  it ".installment_dates should give a list with some dates" do
    dates = @loan.installment_dates
    dates.uniq.size.should eql(@loan.number_of_installments)
    dates.sort[0].should eql(@loan.scheduled_first_payment_date)
    dates.sort[-1].should eql(@loan.scheduled_repaid_on)
    dates.sort[-2].should eql(@loan.shift_date_by_installments(@loan.scheduled_repaid_on, -1))
  end


  it ".payment_schedule should give correct results" do
    @loan.payment_schedule.keys.sort.each_with_index do |k,i|
      case i
        when 0
          k.should == @loan.scheduled_disbursal_date
        when 1
          k.should == @loan.scheduled_first_payment_date 
        else
          k.should == @loan.scheduled_first_payment_date + (7*(i-1))
      end
      ps = @loan.payment_schedule[k]
      ps[:total_principal].should == 40 * (i)
      ps[:total_interest].should == (200/25) * i
    end
  end

  it ".payments_hash should give correct results" do
    @loan.save
    @loan.payments_hash.should_not be_blank
    @loan.disbursal_date = @loan.scheduled_disbursal_date
    @loan.disbursed_by = @manager
    # @loan.id = nil
    @loan.history_disabled=false
    7.times do |i|
      status = @loan.repay(48, @user, @loan.scheduled_first_payment_date + (7*i), @manager)
      status[0].should be_true      
    end
    @loan.update_history
    @loan.payments_hash.keys.sort.each_with_index do |k,i|
      case i
      when 0
        k.should == @loan.scheduled_disbursal_date
      else
        k.should == @loan.scheduled_first_payment_date + (7*(i-1))
      end
      if i >= 3
        ps = @loan.payments_hash[k]
        ps[:total_principal].to_i.should == 40 * (i) unless i > 7
        ps[:total_interest].should == (200/25) * (i) unless i > 7
      end
    end
  end

  it "history should be correct" do
    @loan.payments_hash.should_not be_blank
    @loan.id = nil
    @loan.disbursal_date = @loan.scheduled_disbursal_date
    @loan.disbursed_by = @manager
    @loan.get_status(@loan.scheduled_disbursal_date).should == :disbursed
    @loan.save
    @loan.errors.each {|e| puts e}
    @loan.history_disabled=false
    7.times do |i|
      p = @loan.repay(48, @user, @loan.scheduled_first_payment_date + (7*i), @manager)
      p[0].should be_true
    end
    @loan.update_history
    hist = @loan.calculate_history
    os_prin = 1000
    os_tot = 1200
    hist.each_with_index do |h,i|
      if h[:date] <= @loan.scheduled_disbursal_date
        prin,int = 0
      else
        prin = h[:principal]
        int = h[:interest_paid]
      end
      # puts "#{i}:#{h[:date]}:#{h[:status]}:#{h[:scheduled_outstanding_principal]} : #{h[:principal_due]} : #{h[:interest_due]} : #{h[:actual_outstanding_principal]} : #{h[:principal_paid]} : #{h[:interest_paid]} : #{h[:days_overdue]}!!"
      h[:scheduled_outstanding_principal].should == 1000 - (40*([0,i-2].max))
      h[:scheduled_outstanding_total].should == 1200 -(48 * ([0,i-2].max))
      h[:status].should == STATUSES.index(:disbursed) + 1 if i == 2
      if i > 2
        if i < 10
          h[:principal_due].should == 0
          h[:interest_due].should == 0
          h[:principal_paid].should == 40
          h[:interest_paid].should == 8
          h[:actual_outstanding_principal].should == 1000 -(40 * ([0,i-2].max)) 
        else
          h[:principal_due].should == ((h[:days_overdue] / 7) + 1) * 40
          h[:interest_due].should == ((h[:days_overdue] / 7) + 1) * 8
          h[:principal_paid].should == 0
          h[:interest_paid].should == 0
          h[:actual_outstanding_principal].should == 1000 -(40 * 7) 
          if h[:date] > @loan.scheduled_first_payment_date + (7 * 6)
            h[:days_overdue].should ==  h[:date] - @loan.scheduled_first_payment_date - 49
          end
        end
      end
    end
  end

  it "should write the history correctly into the db" do
    @loan.payments_hash.should_not be_blank
    @loan.id = nil
    @loan.disbursal_date = @loan.scheduled_disbursal_date
    @loan.disbursed_by = @manager
    @loan.get_status(@loan.scheduled_disbursal_date).should == :disbursed
    @loan.save
    @loan.errors.each {|e| puts e}
    @loan.history_disabled=false
    7.times do |i|
      p = @loan.repay(48, @user, @loan.scheduled_first_payment_date + (7*i), @manager)
      p[1].errors.each {|e| puts e}
    end
  end

  it "should not be deleteable if verified" do
    @loan.verified_by = User.first
    @loan.save
    @loan.destroy.should be_false

    @loan.verified_by = nil
    @loan.destroy.should be_true
  end
    
  it ".installment_dates should correctly deal with holidays" do
    Holiday.all.destroy!
    d1 = @loan.installment_dates[5]
    @h = Holiday.new(:name => "test", :date => d1, :shift_meeting => :before)
    @h.save
    @h.should be_valid
    @loan.clear_cache
    @loan.installment_dates[5].should == (d1 - 1)
    @h.shift_meeting = :after
    @h.save
    @loan.clear_cache
    @loan.installment_dates[5].should == (d1 + 1)
    @h.destroy!
    @loan.clear_cache
  end

  it "should give correct cashflow for irr" do
  end

  it "should takeover properly" do
    @loan2 = Object.const_get("#{@loan.discriminator}").new
    @loan2.attributes = @loan.attributes
    @loan_product.min_interest_rate = 0
    @loan_product.min_amount = 0
    @loan_product.save
    @loan2.loan_product = @loan_product
    @loan2.original_amount = @loan.amount
    @loan2.original_disbursal_date = @loan.scheduled_disbursal_date
    @loan2.original_first_payment_date = @loan.scheduled_first_payment_date
    @loan2.taken_over_on_installment_number = 10
    @loan2.valid?; @loan2.errors.each{|e| puts e}
    @loan2.should be_valid
#    @loan._show_cf; @loan2._show_cf
    @loan2.payment_schedule.count.should == @loan.payment_schedule.count - 9
    @loan2.taken_over_on = Date.parse("2001-02-04")
    @loan2.clear_cache
    @loan2.payment_schedule.count.should == @loan.payment_schedule.count - 9
  end

  it "should have correct takeover schedule and balances" do
    @loan_product.max_amount = 8000
    @loan_product.max_number_of_installments = 50
    @loan1 = Loan.create(:amount => 8000, :interest_rate => 0.15, :installment_frequency => :weekly, :number_of_installments => 46, 
                         :discriminator => Loan, :scheduled_first_payment_date => "2009-12-28", :applied_on => "2009-12-22", 
                         :scheduled_disbursal_date => "2009-12-22", :disbursal_date => "2009-12-22", :applied_by       => @manager, 
                         :funding_line     => @funding_line, :client => @client, :loan_product => @loan_product, :approved_on => "2009-12-22",
                         :approved_by => @manager, :disbursed_by => @manager
                         )
    @loan1.errors.each {|e| puts e} unless @loan1.valid?
    @loan1.should be_valid
    orig_schedule = @loan1.payment_schedule

    @loan_product.min_interest_rate = 0
    @loan_product.min_amount = 0
    @loan2 = Object.const_get("#{@loan1.discriminator}").new(:interest_rate => 0.15, :installment_frequency => :weekly, 
                                                             :number_of_installments => 46, :original_amount => @loan1.amount,
                                                             :original_first_payment_date => "2009-12-28", :applied_on => "2009-12-22", 
                                                             :original_disbursal_date => "2009-12-22", :applied_by => @manager, 
                                                             :funding_line => @funding_line, :client => @client, :loan_product => @loan_product, 
                                                             :approved_on => "2009-12-22", :approved_by => @manager, :disbursed_by => @manager,
                                                             :taken_over_on_installment_number => 10, :taken_over_on => "2010-02-28", 
                                                             :scheduled_disbursal_date => "2010-02-28", :amount => 8000, 
                                                             :disbursal_date => "2010-02-28", :scheduled_first_payment_date => "2010-03-01"
                                                             )
    @loan2.save.should be_true
    @loan2.errors.each {|e| puts e} unless @loan2.valid?
    @loan2.should be_valid
#    @loan._show_cf; @loan2._show_cf
    @loan2.payment_schedule.count.should == @loan1.payment_schedule.count - 9
    @loan2.amount.should == 6435
    
    @loan2.payment_schedule.each{|date, ps|
      next if date = @loan2.taken_over_on
      orig_schedule.key?(date).should be_true
      orig_schedule[date][:balance].round.should == ps[:balance].round
      orig_schedule[date][:principal].round.should == ps[:principal].round
      orig_schedule[date][:interest].round.should == ps[:interest].round
    }
    @loan_product = @loan_product.reload
  end

  it "should do deletion of payment" do 
  end

  it "should change with center meeting date change" do
    old_dates = @loan.installment_dates
    @loan_product.loan_validation_methods = "scheduled_dates_must_be_center_meeting_days"
    @loan_product.save
    @loan.scheduled_disbursal_date = Date.new(2000, 06, 14)
    @loan.save
    @loan.should be_valid

    @center.meeting_day_change_date = Date.new(2001, 01, 26)
    @center.meeting_day = :thursday
    @center.save
    @center = Center.get(@center.id)
    @center.meeting_day_for(Date.new(2001, 01, 25)).should eql(:wednesday)
    @center.meeting_day_for(Date.new(2001, 02, 2)).should eql(:thursday)
    @center.meeting_day_for(Date.new(2001, 02, 27)).should eql(:thursday)
    @center.meeting_day_for(Date.new(2001, 01, 24)).should eql(:wednesday)

    @center.next_meeting_date_from(Date.new(2001, 01, 24)).should eql(Date.new(2001, 02, 1))
    @center.previous_meeting_date_from(Date.new(2001, 02, 1)).should eql(Date.new(2001, 01, 24))

    @center.next_meeting_date_from(Date.new(2001, 02, 1)).should eql(Date.new(2001, 02, 8))
    @center.previous_meeting_date_from(Date.new(2001, 02, 8)).should eql(Date.new(2001, 02, 01))

    @center.meeting_day_for(Date.new(2001, 02, 2)).should eql(:thursday)

    @loan = Loan.get(@loan.id)
    new_dates =  @loan.installment_dates
    (old_dates.find_all{|x| x <= Date.new(2001, 01, 26)} - new_dates.find_all{|x| x <= Date.new(2001, 01, 26)}).length.should eql(0)
    (old_dates.find_all{|x| x >  Date.new(2001, 01, 26)} - new_dates.find_all{|x| x >  Date.new(2001, 01, 26)}.map{|x| x-1}).length.should eql(0)

    @loan_product.loan_validation_methods = ""
    @loan_product.save
  end

  it "should change with center meeting date change" do
    @loan_product.loan_validation_methods = "scheduled_dates_must_be_center_meeting_days"
    @loan_product.save
    @center.center_meeting_days.destroy!
    @center = Center.get(@center.id)
    @center.meeting_day_change_date = Date.new(2000, 1, 1)
    @center.meeting_day = :wednesday
    @center.save

    @loan_product.loan_validation_methods = "scheduled_dates_must_be_center_meeting_days"
    @loan_product.save
    @loan = Loan.new(:amount => 1000, :interest_rate => 0.2, :installment_frequency => :weekly, :number_of_installments => 25, :scheduled_first_payment_date => "2000-12-06", 
                     :applied_on => "2000-02-01", :scheduled_disbursal_date => "2000-06-14", :applied_by => @manager, :client => Client.get(@client.id), :funding_line => @funding_line, 
                     :loan_product => @loan_product, :approved_by => @manager, :approved_on => "2000-02-03")
    old_dates = @loan.installment_dates
    @loan.save
    unless @loan.valid?
      p @loan.errors
    end
    @loan.should be_valid
    
    @center.meeting_day_change_date = Date.new(2001, 01, 27)
    @center.meeting_day = :tuesday
    @center.save
    @center = Center.get(@center.id)
    @center.meeting_day_for(Date.new(2001, 01, 24)).should eql(:wednesday)
    @center.meeting_day_for(Date.new(2001, 01, 26)).should eql(:wednesday)
    @center.meeting_day_for(Date.new(2001, 01, 28)).should eql(:tuesday)
    @center.meeting_day_for(Date.new(2001, 01, 30)).should eql(:tuesday)


    @center.next_meeting_date_from(Date.new(2001, 01, 24)).should eql(Date.new(2001, 01, 30))
    @center.previous_meeting_date_from(Date.new(2001, 01, 30)).should eql(Date.new(2001, 01, 24))

    @center.next_meeting_date_from(Date.new(2001, 01, 30)).should eql(Date.new(2001, 02, 6))
    @center.previous_meeting_date_from(Date.new(2001, 02, 6)).should eql(Date.new(2001, 01, 30))

    @loan = Loan.get(@loan.id)
    new_dates =  @loan.installment_dates

    (old_dates.find_all{|x| x <= Date.new(2001, 01, 26)} - new_dates.find_all{|x| x <= Date.new(2001, 01, 26)}).length.should eql(0)
    (old_dates.find_all{|x| x >  Date.new(2001, 01, 26)} - new_dates.find_all{|x| x >  Date.new(2001, 01, 26)}.map{|x| x + 1}).length.should eql(0)
  end
  
  it "should not be valid if duplicated" do
    @loan_product.loan_validation_methods = "loans_must_not_be_duplicated"
    @loan_product.save
    @loan = Loan.new(:amount => 1000, :interest_rate => 0.2, :installment_frequency => :weekly, :number_of_installments => 25, :scheduled_first_payment_date => "2000-12-06", :applied_on => "2000-02-01", :scheduled_disbursal_date => "2000-06-14", :applied_by => @manager, :client => Client.get(@client.id), :funding_line => @funding_line, :loan_product => @loan_product, :approved_by => @manager, :approved_on => "2000-02-03")
    @loan.save.should_not be_true
    client = Client.new(:name => 'Mary', :reference => Time.now.to_s, :client_type => ClientType.create(:type => "Standard"))
    client.center  = @center
    client.date_joined = Date.parse('2006-01-01')
    client.created_by_user_id = 1
    client.client_type_id = 1
    client.save
    client.errors.each {|e| puts e}
    client.should be_valid
    @loan = Loan.new(:amount => 1000, :interest_rate => 0.2, :installment_frequency => :weekly, :number_of_installments => 25, :scheduled_first_payment_date => "2000-12-06", :applied_on => "2000-02-01", :scheduled_disbursal_date => "2000-06-14", :applied_by => @manager, :client => Client.get(client.id), :funding_line => @funding_line, :loan_product => @loan_product, :approved_by => @manager, :approved_on => "2000-02-03")
    @loan.save.should be_true
  end

  it "should repay properly" do
    # this test is failing.
    @loan = Loan.new(:amount => 1000, :interest_rate => 0.2, :installment_frequency => :weekly, :number_of_installments => 25, 
                     :scheduled_first_payment_date => "2000-12-06", 
                     :applied_on => "2000-02-01", :scheduled_disbursal_date => "2000-06-14", 
                     :applied_by => @manager, :client => Client.get(@client.id), :funding_line => @funding_line, 
                     :loan_product => @loan_product, :approved_by => @manager, :approved_on => "2000-02-03")
    @loan.save
    fee =  Fee.create(:amount => 100, :name => "processing fee", :payable_on => :loan_disbursal_date)

    af = ApplicableFee.new(:applicable_id => @loan.id, :applicable_type => 'Loan',
                           :applicable_on => @loan.scheduled_disbursal_date, :fee => fee,
                           :amount => 100)
    af.should be_valid
    af.save.should be_true

    @loan.disbursal_date = @loan.scheduled_disbursal_date
    @loan.disbursed_by = @manager

    r = @loan.repay(500, @user, @loan.scheduled_first_payment_date, @manager)
    r[0].should == true
    r[3].type.should == :fees
    r[3].amount.should == 100
  end

  it "should not disburse if loan fees are not paid" do
    #when fees are not paid
    @loan_product.loan_validation_methods = "check_payment_of_fees_before_disbursal"
    @loan_product.fees[0] = Fee.first 
    @loan_product.save
    @loan = Loan.new(:amount => 1000, :interest_rate => 0.2, :installment_frequency => :weekly, :number_of_installments => 25, :scheduled_first_payment_date => "2000-12-06", :applied_on => "2000-02-01", :scheduled_disbursal_date => "2000-06-14", :applied_by => @manager, :client => Client.get(@client.id), :funding_line => @funding_line, :loan_product => @loan_product, :approved_by => @manager, :approved_on => "2000-02-03")
    @loan.save.should be_true
    @loan.disbursal_date = @loan.scheduled_disbursal_date
    @loan.disbursed_by = @manager
    @loan.save.should be_false
    
    #when fees are paid
    @loan = Loan.new(:amount => 1000, :interest_rate => 0.2, :installment_frequency => :weekly, :number_of_installments => 25, :scheduled_first_payment_date => "2000-12-06", :applied_on => "2000-02-01", :scheduled_disbursal_date => "2000-06-14", :applied_by => @manager, :client => Client.get(@client.id), :funding_line => @funding_line, :loan_product => @loan_product, :approved_by => @manager, :approved_on => "2000-02-03")
    @loan.save.should be_true    
    @loan.pay_fees((@loan.fees[0].amount || 0), @loan.fee_schedule.keys.first, @manager, User.first)
    @loan.disbursal_date = @loan.scheduled_disbursal_date
    @loan.disbursed_by = @manager
    @loan.save.should be_true
  end
end
