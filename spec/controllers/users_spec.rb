require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'test')

describe "Controllers "  do
  before(:all) do
    load_fixtures :users, :staff_members, :branches, :centers, :client_types, :clients, :loan_products #, :loans  #, :payments
    @u_data_entry = User.new(:login => 'data', :password => 'entry', :password_confirmation => 'entry', :role => :data_entry)
    @u_data_entry.save
    @u_read_only = User.new(:login => 'read', :password => 'only', :password_confirmation => 'only', :role => :read_only)
    @u_read_only.save
    @u_mis_manager = User.new(:login => 'mis', :password => 'manager', :password_confirmation => 'manager', :role => :mis_manager)
    @u_mis_manager.save

    @funder = Funder.new(:name => "FWWB")
    @funder.save
    @funder.should be_valid

    @funding_line = FundingLine.new(:amount => 10_000_000, :interest_rate => 0.15, :purpose => "for women", :disbursal_date => "2006-02-02", 
                                    :first_payment_date => "2007-05-05", :last_payment_date => "2009-03-03")
    @funding_line.funder = @funder
    @funding_line.save
    @funding_line.should be_valid

  end

  it "should fail with improper credentials" do
    response = request url(:perform_login), :method => "PUT", :params => {:login => 'no_such_user', :password => 'bad_password'}
    response.should_not be_successful
  end
  it "should deny access to the data" do
    request("/branches").should_not be_successful
  end

  it "should login with correct credentials" do
    response = request url(:perform_login), :method => "PUT", :params => {:login => 'admin', :password => 'password'}
    response.should redirect

    request("/branches").should be_successful
  end

  it "should check read_only_user credentials" do
    response = request url(:perform_login), :method => "PUT", :params => {:login => 'read', :password => 'only'}
    response.should redirect
    request("/branches").should be_successful
    @user = User.get(1)
    response = request(url(:new_user)).body.to_s.should =~ /Not Privileged/ 
    request(url(:edit_user, @user.id)).body.to_s.should =~ /Not Privileged/ 
    request(url(:delete_user, @user.id)).body.to_s.should =~ /Not Privileged/ 
    
    @staff = StaffMember.get(1)
    request(url(:new_staff_member)).body.to_s.should =~ /Not Privileged/ 
    request(url(:edit_staff_member, @staff.id)).body.to_s.should =~ /Not Privileged/
    
    @branch = Branch.get(1)
    request(url(:new_branch)).body.to_s.should =~ /Not Privileged/ 
    request(url(:edit_branch, @branch.id)).body.to_s.should =~ /Not Privileged/ 

    @center = Center.get(1)
    request(url(:new_branch_center, @branch.id)).body.to_s.should =~ /Not Privileged/ 
    request(url(:edit_branch_center, @branch.id, @center.id)).body.to_s.should =~ /Not Privileged/

    @client = Client.get(1)
    request(url(:new_branch_center_client, @branch.id, @center.id)).body.to_s.should =~ /Not Privileged/ 
    request(url(:edit_branch_center_client, @branch.id, @center.id, @client.id)).body.to_s.should =~ /Not Privileged/ 

    @loan_product = LoanProduct.get(2)

    @loan = Loan.new(:amount => @loan_product.min_amount, :interest_rate => @loan_product.min_interest_rate/100.0, :installment_frequency => :weekly, 
                     :number_of_installments => @loan_product.min_number_of_installments, :scheduled_first_payment_date => Date.today, :applied_on => Date.today-7, 
                     :applied_by => @staff, :scheduled_disbursal_date => Date.today-7, :client => @client, :loan_product => @loan_product, 
                     :funding_line => FundingLine.first)
    @loan.should be_valid
    if @loan.save
      request(url(:new_branch_center_client_loan, @branch.id, @center.id, @client.id)).body.to_s.should =~ /Not Privileged/ 
      request(url(:edit_branch_center_client_loan, @branch.id, @center.id, @client.id, @loan.id)).body.to_s.should =~ /Not Privileged/ 
    else
      p @loan.errors
    end

    @user = User.get(1)
    request(url(:users)).body.to_s.should  =~ /Not Privileged/ 
#    request(url(:users, @user.id)).body.to_s.should be_successful
    request(url(:new_user)).body.to_s.should  =~ /Not Privileged/ 
    request(url(:edit_user, @user.id)).body.to_s.should  =~ /Not Privileged/ 
    request(url(:delete_user, @user.id)).body.to_s.should  =~ /Not Privileged/ 

    request(url(:enter_loans)).body.to_s.should  =~ /Not Privileged/ 
    request(url(:enter_payments)).body.to_s.should  =~ /Not Privileged/ 
    request(url(:data_entry)).body.to_s.should  =~ /Not Privileged/ 
    request(url(:enter_clients)).body.to_s.should  =~ /Not Privileged/ 
    request(url(:enter_attendancy)).body.to_s.should  =~ /Not Privileged/ 
  end

  it "should check data_entry_operator credentials" do
    response = request url(:perform_login), :method => "PUT", :params => {:login => 'data', :password => 'entry'}
    response.should redirect
    request("/branches").should_not be_successful
    @user = User.get(1)
    response = request(url(:new_user)).body.to_s.should =~ /Not Privileged/ 
    request(url(:edit_user, @user.id)).body.to_s.should =~ /Not Privileged/ 
    request(url(:delete_user, @user.id)).body.to_s.should =~ /Not Privileged/ 
    
    @staff = StaffMember.get(1)
    request(url(:new_staff_member)).body.to_s.should =~ /Not Privileged/ 
    request(url(:edit_staff_member, @staff.id)).body.to_s.should =~ /Not Privileged/
    
    @branch = Branch.get(1)
    request(url(:new_branch)).body.to_s.should =~ /Not Privileged/ 
    request(url(:edit_branch, @branch.id)).body.to_s.should =~ /Not Privileged/ 
    request(url(:delete_branch, @branch.id)).body.to_s.should =~ /Not Privileged/

    @center = Center.get(1)
    request(url(:new_branch_center, @branch.id)).body.to_s.should =~ /Not Privileged/ 
    request(url(:edit_branch_center, @branch.id, @center.id)).body.to_s.should =~ /Not Privileged/
    request(url(:delete_branch_center, @branch.id, @center.id)).body.to_s.should =~ /Not Privileged/

    @client = Client.get(1)
    request(url(:new_branch_center_client, @branch.id, @center.id)).body.to_s.should =~ /Not Privileged/ 
    request(url(:edit_branch_center_client, @branch.id, @center.id, @client.id)).body.to_s.should =~ /Not Privileged/ 
    request(url(:delete_branch_center_client, @branch.id, @center.id, @client.id)).body.to_s.should =~ /Not Privileged/ 
    @loan_product = LoanProduct.get(2)
    today = Date.today
    @loan = Loan.new(:amount => @loan_product.min_amount, :interest_rate => @loan_product.min_interest_rate/100.0, :installment_frequency => :weekly, 
                     :number_of_installments => @loan_product.min_number_of_installments, :scheduled_first_payment_date => today, :funding_line => FundingLine.first,
                     :applied_on => today-7, :applied_by => @staff, :scheduled_disbursal_date => today-7, :client => @client, :loan_product => @loan_product)
    @loan.should be_valid
    if @loan.save
      request(url(:new_branch_center_client_loan, @branch.id, @center.id, @client.id)).body.to_s.should =~ /Not Privileged/
      request(url(:edit_branch_center_client_loan, @branch.id, @center.id, @client.id, @loan.id)).body.to_s.should =~ /Not Privileged/ 
      request(url(:delete_branch_center_client_loan, @branch.id, @center.id, @client.id, @loan.id)).body.to_s.should =~ /Not Privileged/ 
    else
      p @loan.errors
    end

    @user = User.get(1)
    request(url(:users)).body.to_s.should  =~ /Not Privileged/ 

    request(url(:new_user)).body.to_s.should  =~ /Not Privileged/ 
    request(url(:edit_user, @user.id)).body.to_s.should  =~ /Not Privileged/ 
    request(url(:delete_user, @user.id)).body.to_s.should  =~ /Not Privileged/ 
  end

  it "should check mis_manager credentials" do
    response = request url(:perform_login), :method => "PUT", :params => {:login => 'mis', :password => 'manager'}
    response.should redirect
    request("/branches").should be_successful
    # MIS Manager cannot manipulate users
    @user = User.get(1)
    request(url(:new_user)).body.to_s.should  =~ /Not Privileged/  
    request(url(:edit_user, @user.id)).body.to_s.should  =~ /Not Privileged/ 
    request(url(:delete_user, @user.id)).body.to_s.should  =~ /Not Privileged/ 
    
    # but he can do the rest
    @staff = StaffMember.get(1)
    request(url(:new_staff_member)).should be_successful
    request(url(:edit_staff_member, @staff.id)).should be_successful
    
    @branch = Branch.get(1)
    request(url(:new_branch)).should be_successful
    request(url(:edit_branch, @branch.id)).should be_successful 

    @center = Center.get(1)
    request(url(:new_branch_center, @branch.id)).should be_successful
    request(url(:edit_branch_center, @branch.id, @center.id)).should be_successful 

    @client = Client.get(1)
    request(url(:new_branch_center_client, @branch.id, @center.id)).should be_successful 
    request(url(:edit_branch_center_client, @branch.id, @center.id, @client.id)).should be_successful 

    @loan_product = LoanProduct.get(2)
    @loan = Loan.new(:amount => @loan_product.min_amount, :interest_rate => @loan_product.min_interest_rate/100.0, :installment_frequency => :weekly, 
                     :number_of_installments => @loan_product.min_number_of_installments, :scheduled_first_payment_date => Date.today, 
                     :funding_line => FundingLine.first, :applied_on => Date.today-7, :applied_by => @staff, 
                     :scheduled_disbursal_date => Date.today-7, :client => @client, :loan_product => @loan_product)
    @loan.should be_valid
    if @loan.save
      request(url(:branch_center_client_loan_payments, @branch.id, @center.id, @client.id, @loan.id)).should be_successful 
      request(url(:new_branch_center_client_loan, @branch.id, @center.id, @client.id)).should be_successful 
      request(url(:edit_branch_center_client_loan, @branch.id, @center.id, @client.id, @loan.id)).should be_successful
    else
      p @loan.errors
    end
  end

  it "should check admin credentials" do
    response = request url(:perform_login), :method => "PUT", :params => {:login => 'admin', :password => 'password'}
    response.should redirect
    request("/branches").should be_successful

    @user = User.get(1)
    request(url(:new_user)).should be_successful # how to check for NotPrivileged error? should raise_error doesn't work
    request(url(:edit_user, @user.id)).should be_successful 
    request(url(:delete_user, @user.id)).should be_successful 
    
    @staff = StaffMember.get(1)
    request(url(:new_staff_member)).should be_successful
    request(url(:edit_staff_member, @staff.id)).should be_successful
    
    @branch = Branch.get(1)
    request(url(:new_branch)).should be_successful
    request(url(:edit_branch, @branch.id)).should be_successful 

    @center = Center.get(1)
    request(url(:new_branch_center, @branch.id)).should be_successful
    request(url(:edit_branch_center, @branch.id, @center.id)).should be_successful 

    @client = Client.get(1)
    request(url(:new_branch_center_client, @branch.id, @center.id)).should be_successful 
    request(url(:edit_branch_center_client, @branch.id, @center.id, @client.id)).should be_successful 
    @loan_product = LoanProduct.get(2)    
    @loan = Loan.new(:amount => @loan_product.min_amount, :interest_rate => @loan_product.min_interest_rate/100.0, :installment_frequency => :weekly, 
                     :number_of_installments => @loan_product.min_number_of_installments, :scheduled_first_payment_date => Date.today, 
                     :applied_on => Date.today-7, :applied_by => @staff, :scheduled_disbursal_date => Date.today-7, :client => @client, 
                     :loan_product => @loan_product, :funding_line => FundingLine.first)
    @loan.should be_valid
    if @loan.save
      request(url(:branch_center_client_loan_payments, @branch.id, @center.id, @client.id, @loan.id)).should be_successful 
      request(url(:new_branch_center_client_loan, @branch.id, @center.id, @client.id)).should be_successful 
      request(url(:edit_branch_center_client_loan, @branch.id, @center.id, @client.id, @loan.id)).should be_successful
      #    request(url(:delete_branch_center_client_loan, @branch.id, @center.id, @client.id, @loan.id)).should be_successful 
    else
      p @loan.errors
    end
  end
end
