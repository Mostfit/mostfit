require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Client do

  before(:all) do
    @manager = StaffMember.new(:name => "Mrs. M.A. Nerger")
    @manager.save
    @manager.should be_valid
    
    @user = User.new(:login => 'Joey', :password => 'password', :password_confirmation => 'password', :role => :admin, :active => true)
    @user.should be_valid
    @user.save

    @user = User.new(:login => "clientcreator", :password => "client", :password_confirmation => "client", :role => :admin)
    @user.save
    @user.should be_valid

    @branch = Branch.new(:name => "Kerela branch")
    @branch.manager = @manager
    @branch.code = "bra"
    @branch.save
    @branch.should be_valid

    @center = Center.new(:name => "Munnar hill center")
    @center.manager = @manager
    @center.branch = @branch
    @center.code = "cen"
    @center.save
    @center.should be_valid

    @loan_product = LoanProduct.new
    @loan_product.name = "LP1"
    @loan_product.min_amount = 1000
    @loan_product.max_amount = 100000
    @loan_product.max_interest_rate = 100
    @loan_product.min_interest_rate = 0.1
    @loan_product.installment_frequency = :weekly
    @loan_product.min_number_of_installments = 1
    @loan_product.max_number_of_installments = 125
    @loan_product.loan_type = "DefaultLoan"
    @loan_product.valid_from = Date.parse('2000-01-01')
    @loan_product.valid_upto = Date.parse('2012-01-01')
    @loan_product.save
    @loan_product.errors.each {|e| puts e}
    @loan_product.should be_valid
    @client_type = ClientType.create(:type => "standard")
  end

  before(:each) do
    Client.all.destroy!
    @client = Client.new(:name => 'Ms C.L. Ient', :reference => 'XW000-2009.01.05', :date_joined => Date.today, 
                         :client_type => @client_type, :created_by => User.first)
    @client.center  = @center
    @client.save
    @client.should be_valid
  end

  it "should not be valid without belonging to a center" do
    @client.center = nil
    @client.should_not be_valid
  end

  it "should not be valid without a name" do
    @client.name = nil
    @client.should_not be_valid
  end

  it "should not be valid without a reference" do
    @client.reference = nil
    @client.should_not be_valid
  end

  it "should not be valid with name shorter than 3 characters" do
    @client.name = "ok"
    @client.should_not be_valid
  end

  it "should have a joining date" do
    @client.date_joined = nil
    @client.should_not be_valid
  end

  it "should be able to 'have' loans" do
    @loan = Loan.new(:amount => 1000, :interest_rate => 0.2, :installment_frequency => :weekly, :number_of_installments => 25, :scheduled_first_payment_date => "2000-12-06", :applied_on => "2000-02-03", :scheduled_disbursal_date => "2000-06-13", :loan_product_id => @loan_product.id)
    @loan.save
    @loan.should_not be_valid
    @loan.applied_by  = @manager
    @loan.client      = @client

    @funder = Funder.new(:name => "FWWB")
    @funder.should be_valid
    @funder.save
    @funding_line = FundingLine.new(:amount => 10_000_000, :interest_rate => 0.15, :purpose => "for women", :disbursal_date => "2006-02-02", :first_payment_date => "2007-05-05", :last_payment_date => "2009-03-03")
    @funding_line.funder = @funder
    @funding_line.save
    @funding_line.should be_valid

    @loan.funding_line = @funding_line
    @loan.approved_on = "2000-02-03"
    @loan.approved_by = @manager
    @loan.loan_product = @loan_product
    @loan.save
    @loan.errors.each {|e| p e}
    @loan.should be_valid

    @client.loans << @loan
    @client.valid?
    @client.errors.each {|e| puts e}
    @client.should be_valid
    @client.loans.first.amount.should eql(1000)
    @client.loans.first.installment_frequency.should eql(:weekly)


    loan2 = Loan.new(:amount => 10000, :interest_rate => 0.2, :installment_frequency => :weekly, :number_of_installments => 40, :scheduled_first_payment_date => "2000-12-07", :applied_on => "2000-02-04", :approved_on => "2000-02-04", :scheduled_disbursal_date => "2000-06-14")
    loan2.applied_by   = @manager
    loan2.approved_by  = @manager
    loan2.client       = @client
    loan2.funding_line = @funding_line
    loan2.loan_product = @loan_product
    loan2.save
    loan2.errors.each {|e| puts e}
    loan2.should be_valid

    @client.loans << loan2
    @client.should be_valid
    @client.loans.size.should eql(2)
  end

  it "should not have more than one outstanding loan at a time if so specified"

  it "should deal with death of a client" do
    @client.deceased_on = Date.today
  end

end
