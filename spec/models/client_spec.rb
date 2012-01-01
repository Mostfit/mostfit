require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Client do

  before(:all) do
    @manager = Factory(:staff_member)
    @manager.save
    
    @branch = Factory(:branch, :manager => @manager)
    @branch.should be_valid

    @center = Factory(:center, :manager => @manager, :branch => @branch)
    @center.should be_valid

    @user = Factory(:user)
    @user.should be_valid

    @loan_product = Factory(:loan_product)
    @loan_product.should be_valid

    @client_type = Factory(:client_type)
  end

  before(:each) do
    Client.all.destroy!
    @client = Factory(:client, :center => @center)
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
    loan = Factory(:loan, :applied_by => @manager, :client => @client, :amount => 1000, :installment_frequency => :weekly)
    loan.should be_valid

    @client.loans << loan
    @client.save
    @client.loans.first.amount.to_i.should eql(1000)
    @client.loans.first.installment_frequency.should eql(:weekly)

    loan2 = Factory(:loan, :applied_by => @manager, :approved_by => @manager, :approved_on => Date.new(2010, 01, 01), :client => @client)
    loan2.should be_valid

    @client.loans << loan2
    @client.save  # Datamapper doesn't automatically save after adding a loan
    @client.should be_valid
    # Make sure to use count and not size to check the actual database records, not just the in-memory object
    @client.loans.count.should eql(2)
  end

  it "should not be deleteable if verified" do
    @client.verified_by = @user
    @client.save
    @client.destroy.should be_false

    @client.verified_by = nil
    @client.destroy.should be_true
  end

  # There are no assertions here...
  it "should deal with death of a client" do
    @client.deceased_on = Date.today
  end

end
