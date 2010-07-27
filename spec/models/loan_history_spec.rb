require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe LoanHistory do

  before(:all) do
    DataMapper.auto_migrate! if Merb.orm == :datamapper
    @user = User.new(:id => 234, :login => 'Joey', :password => 'password', :password_confirmation => 'password', :role => :admin)
    @user.save
    @user.should be_valid

    @manager = StaffMember.new(:name => "Mrs. M.A. Nerger")
    @manager.save
    @manager.should be_valid

    @funder = Funder.new(:name => "FWWB", :id => 1)
    @funder.save
    @funder.should be_valid

    @funding_line = FundingLine.new(:id => 1, :amount => 10_000_000, :interest_rate => 0.15, :purpose => "for women", :disbursal_date => "2006-02-02", :first_payment_date => "2007-05-05", :last_payment_date => "2009-03-03")
    @funding_line.funder = @funder
    @funding_line.save
    @funding_line.should be_valid

    @branch = Branch.new(:name => "Kerela branch", :id => 1)
    @branch.manager = @manager
    @branch.code = "bra"
    @branch.save
    @branch.should be_valid

    @center = Center.new(:name => "Munnar hill center", :id => 1)
    @center.manager = @manager
    @center.branch  = @branch
    @center.code = "cen"
    @center.save
    @center.should be_valid
    ClientType.create(:type => "Standard")

    @client = Client.new(:name => 'Ms C.L. Ient', :reference => 'XW000-2009.01.05', :date_joined => Date.parse('2000-01-01'), 
                         :client_type => ClientType.first, :created_by => User.first)
    @client.center  = @center
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


    @loan = Loan.new( :amount => 1000, :interest_rate => 0.2, :installment_frequency => :weekly, :number_of_installments => 25, :scheduled_first_payment_date => "2000-12-06", :applied_on => "2000-02-01", :scheduled_disbursal_date => "2000-06-13")
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
    @loan.should be_valid
    @history = LoanHistory.all(:loan_id => 1)
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
    @loanhistory1=LoanHistory.new(:loan_id=>12345,:date=>"2001-02-02",:scheduled_outstanding_principal=>800,
                                  :scheduled_outstanding_total=>900,:actual_outstanding_principal=>820,:actual_outstanding_total=>920 ,:status=>:approved)
    @loanhistory1.save
    @loanhistory2=LoanHistory.new(:loan_id=>12345,:date=>"2001-02-02",:scheduled_outstanding_principal=>800,
                                  :scheduled_outstanding_total=>900,:actual_outstanding_principal=>820,:actual_outstanding_total=>920 ,:status=>:approved)
    @loanhistory2.save	
    @loanhistory2.should_not be_valid
  end

  it "should have correct number of periods" do
    @loan.save
    begin; @loan.should be_valid; rescue; puts @loan.errors.inspect; end
    @loan.update_history
    history = LoanHistory.all(:loan_id => 1)
    history.size.should == 28 # applied_on, approved_on, disbursal_date and 30 installments
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


end
