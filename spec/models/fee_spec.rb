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
    @center.save
    @center.errors.each {|e| puts e}
    @center.should be_valid

    @client = Client.new(:name => 'Ms C.L. Ient', :reference => Time.now.to_s)
    @client.center  = @center
    @client.date_joined = Date.parse('2006-01-01')
    @client.save
    @client.errors.each {|e| puts e}
    @client.should be_valid
    # validation needs to check for uniqueness, therefor calls the db, therefor we dont do it
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
    @loan = Loan.new(:amount => 1000, :interest_rate => 0.2, :installment_frequency => :weekly, :number_of_installments => 25, :scheduled_first_payment_date => "2000-12-06", :applied_on => "2000-02-01", :scheduled_disbursal_date => "2000-06-13")
    @loan.history_disabled = true
    @loan.applied_by       = @manager
    @loan.funding_line     = @funding_line
    @loan.client           = @client
    @loan.loan_product     = @loan_product
    @loan.valid?
    @loan.errors.each {|e| puts e}
    @loan.should be_valid

  end


  before :each do
    @f = Fee.new
    @f.name = "Test Fee"
    @f.payable_on = :applied_on
  end

  it "should have a name" do
    @f.name = nil
    @f.should_not be_valid
  end

  it "should have either an amount or a percentage" do
    @f.should_not be_valid
    @f.amount = 1000
    @f.should be_valid
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


  it "should return correct fee_schedule for loan" do
    @f.percentage = 0.1
    @loan_product.fees << @f 
    @loan.fee_schedule.should == {@loan.applied_on => {"Test Fee" => 100}}
  end
  
  it "should return correct fee_schedule for multiple fees even on the same date" do
    @f2 = Fee.new(:name => "Other Fee")
    @f2.amount = 111
    @f2.payable_on = :applied_on
    @f2.should be_valid
    @f.percentage = 0.1
    @loan_product.fees << @f
    @loan_product.fees << @f2
    @loan.fee_schedule.should == {@loan.applied_on => {"Test Fee" => 100, "Other Fee" => 111}}
  end

  it "should return correct fees payable" do
    @f2 = Fee.new(:name => "Other Fee")
    @f2.amount = 111
    @f2.payable_on = :applied_on
    @f2.should be_valid
    @f.percentage = 0.1
    @loan_product.fees << @f
    @loan_product.fees << @f2
    @loan.fees_payable.should == {@loan.applied_on => {"Test Fee" => 100, "Other Fee" => 111}}
  end


  it "should return correct fees_paid" do
    @f2 = Fee.new(:name => "Other Fee")
    @f2.amount = 111
    @f2.payable_on = :applied_on
    @f2.should be_valid
    @f.percentage = 0.1
    @loan_product.fees << @f
    @loan_product.fees << @f2
    @loan
  end    
  

end
