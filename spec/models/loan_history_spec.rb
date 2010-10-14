require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe LoanHistory do
  before(:all) do
    load_fixtures :users, :staff_members, :branches, :funders, :funding_lines
    $holidays = {}
    Center.all.destroy
    CenterMeetingDay.all.destroy
    @user = User.first
    @manager = StaffMember.first
    @funder = Funder.first
    @funding_line = FundingLine.first
    @branch = Branch.first

    @center = Center.new(:name => "Munnar hill center", :id => 1, :manager => @manager, :branch => @branch, :code => "cen", :meeting_day => :wednesday)
    @center.save
    @center.should be_valid
    ClientType.create(:type => "Standard")

    @client = Client.new(:name => 'Ms C.L. Ient', :reference => 'XW000-2009.01.05', :date_joined => Date.parse('2000-01-01'), 
                         :client_type => ClientType.first, :created_by => @user, :center => @center)
    @client.save
    @client.errors.each{|e| puts e}
    @client.should be_valid

    @loan_product = LoanProduct.new
    @loan_product.name = "LP1"
    @loan_product.max_amount = 1000
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


    @loan = Loan.new(:amount => 1000, :interest_rate => 0.2, :installment_frequency => :weekly, :number_of_installments => 25, 
                     :scheduled_first_payment_date => "2000-12-06", :applied_on => "2000-02-01", :scheduled_disbursal_date => "2000-06-13")
    @loan.applied_by       = @manager
    @loan.funding_line     = @funding_line
    @loan.client           = @client
    @loan.loan_product     = @loan_product
    @loan.should be_valid
    
    @loan.approved_on = "2000-02-03"
    @loan.approved_by = @manager
    @loan.disbursal_date = @loan.scheduled_disbursal_date
    @loan.disbursed_by = @manager
    @loan.save
    @loan.history_disabled = false
    @loan.update_history
    @loan.should be_valid
    @history = LoanHistory.all(:loan_id => @loan.id)
    @history.should_not be_blank
    @loanhistory = @history.first
    @loanhistory.should_not be_nil
  end

  it "should not be valid without scheduled outstanding principal" do
    # debugger
    @loanhistory.scheduled_outstanding_principal=nil
    @loanhistory.should_not be_valid
  end

  it "should not be valid without scheduled outstanding total" do
    @loanhistory.scheduled_outstanding_total=nil
    @loanhistory.should_not be_valid
  end

  it "should not be valid without actual outstanding principal" do
    @loanhistory.actual_outstanding_principal=nil
    @loanhistory.should_not be_valid
  end

  it "should not be valid without actual outstanding total" do
    @loanhistory.actual_outstanding_total=nil
    @loanhistory.should_not be_valid
  end

  it "should not be valid without having a proper status" do
    @loanhistory.status="ready"
    @loanhistory.should_not be_valid
    @loanhistory.status=nil
    @loanhistory.should_not be_valid
  end

  it "should not be valid if the combination if loan id and date is not unique" do
    @loanhistory1=LoanHistory.new(:loan_id => 12345, :date => "2001-02-02", :scheduled_outstanding_principal => 800,
                                  :scheduled_outstanding_total => 900, :actual_outstanding_principal => 820, :actual_outstanding_total => 920 , :status => :approved)
    @loanhistory1.save
    @loanhistory2=LoanHistory.new(:loan_id => 12345, :date=> "2001-02-02", :scheduled_outstanding_principal => 800,
                                  :scheduled_outstanding_total => 900, :actual_outstanding_principal => 820, :actual_outstanding_total => 920 ,:status => :approved)
    @loanhistory2.save
    @loanhistory2.should_not be_valid
  end

  it "should have correct number of periods" do
    @loan.save
    begin; @loan.should be_valid; rescue; puts @loan.errors.inspect; end
    @loan.update_history
    history = LoanHistory.all(:loan_id => @loan.id)
    history.size.should == 28 # applied_on, approved_on, disbursal_date and 25 installments
  end

  it "should start with the application date, approval date, disbursal date and first payment date" do
    @history[0].date.should == @loan.applied_on
    @history[1].date.should == @loan.approved_on
    @history[2].date.should == @loan.scheduled_disbursal_date
    @history[3].date.should == @loan.scheduled_first_payment_date
  end

  it "should have the following dates afterwards" do
    (0..@loan.number_of_installments - 1).each do |i|
      @history[i+3].date.should == @loan.scheduled_first_payment_date + (i * 7)
    end
  end

  it "should have correct amounts" do
    (1..@loan.number_of_installments - 1).each do |i|
      @history[i+2].principal_paid.should == 0 # @loan.scheduled_principal_for_installment(i)
      @history[i+2].interest_paid.should == 0 # @loan.scheduled_interest_for_installment(i)
      # @history[i+3].amount_in_default.should == 0
      @history[i+2].days_overdue.should == [0,@loan.date_for_installment(i) - @loan.scheduled_first_payment_date].max
      @history[i+2].scheduled_outstanding_principal.should == 1000 - (1000/25 * (i)).to_i
    end
    @history[27].scheduled_outstanding_principal.should == 0
    @history[27].status.should == :outstanding
  end


  it "should give correct number of loans outstanding" do
    LoanHistory.sum_outstanding_grouped_by(@loan.scheduled_disbursal_date, [:loan]).first.scheduled_outstanding_principal.should == 1000
    @loan.repay(96, @user, @loan.scheduled_first_payment_date, @manager)
    data = LoanHistory.sum_outstanding_grouped_by(@loan.scheduled_first_payment_date, [:loan]).first
    data.scheduled_outstanding_principal.should == 960
    data.actual_outstanding_principal.should == 912
    
    @loan.repay(48, @user, @loan.scheduled_first_payment_date + 7, @manager)
    LoanHistory.sum_outstanding_grouped_by(@loan.scheduled_first_payment_date + 7, [:loan]).first.scheduled_outstanding_principal.should == 920
    LoanHistory.sum_outstanding_grouped_by(@loan.scheduled_first_payment_date + 7, [:loan]).first.actual_outstanding_principal.should == 872

    LoanHistory.sum_outstanding_grouped_by(@loan.scheduled_first_payment_date + 14, [:loan]).first.scheduled_outstanding_principal.should == 880
    LoanHistory.sum_outstanding_grouped_by(@loan.scheduled_first_payment_date + 14, [:loan]).first.actual_outstanding_principal.should == 872    
  end

  it "should give correct amount for loans defaulted" do
    default =  LoanHistory.defaulted_loan_info_by(:loan, @loan.scheduled_first_payment_date + 21).first
    default.pdiff.should == 32
    default.tdiff.should == 48

    default =  LoanHistory.defaulted_loan_info_by(:loan, @loan.scheduled_first_payment_date + 28).first
    default.pdiff.should == 72
    default.tdiff.should == 96

    default =  LoanHistory.defaulted_loan_info_by(:loan, @loan.scheduled_first_payment_date + 35).first
    default.pdiff.should == 112
    default.tdiff.should == 144
  end

  it "should give correct loans defaulted for" do
    due = LoanHistory.defaulted_loan_info_for(@loan.client, @loan.scheduled_first_payment_date + 35)
    due.principal_due.should == 112
    due.total_due.should == 144
    
    @client_2 = Client.new
    attr    = @client.attributes.dup
    attr.delete(:id)
    @client_2.attributes = attr
    @client_2.reference = @client.reference + "1"
    @client_2.save

    @loan_2 = Loan.new
    attr    = @loan.attributes.dup
    attr.delete(:id)
    @loan_2.attributes = attr
    @loan_2.client = @client_2
    @loan_2.save
    
    due = LoanHistory.defaulted_loan_info_for(@center, @loan.scheduled_first_payment_date + 7)
    due.principal_due.should == 80
    due.total_due.should == 96
    
    due = LoanHistory.defaulted_loan_info_for(@center, @loan.scheduled_first_payment_date + 14)
    due.principal_due.should == 120
    due.total_due.should == 144

    due = LoanHistory.defaulted_loan_info_for(@center, @loan.scheduled_first_payment_date + 21)
    due.principal_due.should == 160 + 32
    due.total_due.should     == 192 + 48

    due = LoanHistory.defaulted_loan_info_for(@center, @loan.scheduled_first_payment_date + 28)
    due.principal_due.should == 200 + 72
    due.total_due.should     == 240 + 96

    @center_2 = Center.new
    attr      = @center.attributes.dup
    attr.delete(:id)
    @center_2.attributes = attr
    @center_2.code = @center.code + "1"
    @center_2.save

    @client_3 = Client.new
    attr    = @client.attributes.dup
    attr.delete(:id)
    @client_3.center = @center_2
    @client_3.attributes = attr
    @client_3.reference = @client.reference + "2"
    @client_3.save

    @loan_3 = Loan.new
    attr    = @loan.attributes.dup
    attr.delete(:id)
    @loan_3.attributes = attr
    @loan_3.client = @client_3
    @loan_3.save
    
    due = LoanHistory.defaulted_loan_info_for(@center, @loan.scheduled_first_payment_date + 28)
    due.principal_due.should == 200 + 72
    due.total_due.should     == 240 + 96

    due = LoanHistory.defaulted_loan_info_for(@center_2, @loan.scheduled_first_payment_date + 7)    
    due.principal_due.should == 2 * 40
    due.total_due.should     == 2 * 48

    due = LoanHistory.defaulted_loan_info_for(@center_2, @loan.scheduled_first_payment_date + 28)    
    due.principal_due.should == 5 * 40
    due.total_due.should     == 5 * 48

    due = LoanHistory.defaulted_loan_info_for(@branch, @loan.scheduled_first_payment_date + 28)
    due.principal_due.should == 5 * 40 + 272
    due.total_due.should     == 5 * 48 + 336
  end

  it "should get correct scheduled outstanding grouped by" do
    LoanHistory.sum_outstanding_grouped_by(@loan.scheduled_first_payment_date - 7, [:loan]).map{|lh|
      lh.scheduled_outstanding_principal
    }.reduce(0){|s, x| s+=x}.should == 3000

    LoanHistory.sum_outstanding_grouped_by(@loan.scheduled_first_payment_date, [:loan]).map{|lh|
      lh.scheduled_outstanding_principal
    }.reduce(0){|s, x| s+=x}.should == 3000 - 120

    LoanHistory.sum_outstanding_grouped_by(@loan.scheduled_first_payment_date + 7, [:loan]).map{|lh|
      lh.scheduled_outstanding_principal
    }.reduce(0){|s, x| s+=x}.should == 3000 - 120 -120
  end

  it "should get correct actual outstanding grouped by" do
    LoanHistory.sum_outstanding_grouped_by(@loan.scheduled_first_payment_date - 7, [:loan]).map{|lh|
      lh.actual_outstanding_principal
    }.reduce(0){|s, x| s+=x}.should == 3000

    LoanHistory.sum_outstanding_grouped_by(@loan.scheduled_first_payment_date, [:loan]).map{|lh|
      lh.actual_outstanding_principal
    }.reduce(0){|s, x| s+=x}.should == 3000 - 96 + 8

    LoanHistory.sum_outstanding_grouped_by(@loan.scheduled_first_payment_date + 7, [:loan]).map{|lh|
      lh.actual_outstanding_principal
    }.reduce(0){|s, x| s+=x}.should == 3000 - 96 + 8 - 40
  end

end
