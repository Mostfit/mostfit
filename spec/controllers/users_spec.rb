require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')

describe "Controllers "  do
  before(:all) do
    load_fixtures :users, :client_types, :staff_members, :branches, :centers, :clients, :loan_products, :funders, :funding_lines #, :loans  #, :payments

    User.all(:login.not => 'admin').destroy!
    @u_data_entry = User.new(:login => 'data', :password => 'entry1', :password_confirmation => 'entry1', :role => :data_entry)
    @u_data_entry.should be_valid
    @u_data_entry.save

    @u_read_only = User.new(:login => 'read', :password => 'only12', :password_confirmation => 'only12', :role => :read_only)
    @u_read_only.should be_valid
    @u_read_only.save

    @u_mis_manager = User.new(:login => 'mis', :password => 'manager', :password_confirmation => 'manager', :role => :mis_manager)
    @u_mis_manager.should be_valid
    @u_mis_manager.save

    @u_center_manager = User.new(:login => 'center', :password => 'center', :password_confirmation => 'center', :role => :staff_member, :staff_member => Center.first.manager)
    @u_center_manager.should be_valid
    @u_center_manager.save

    @u_branch_manager = User.new(:login => 'branch', :password => 'branch', :password_confirmation => 'branch', :role => :staff_member, :staff_member => Branch.first.manager)
    @u_branch_manager.should be_valid
    @u_branch_manager.save
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
    response = request url(:perform_login), :method => "PUT", :params => {:login => 'read', :password => 'only12'}
    response.should redirect
    request("/branches").should be_successful
    @user = User.get(1)
    response = request(url(:new_user)).body.to_s.should =~ /Not Privileged/ 
      request(url(:edit_user, @user.id)).body.to_s.should =~ /Not Privileged/ 
      #    request(url(:delete_user, @user.id)).body.to_s.should =~ /Not Privileged/ 

      @staff = StaffMember.get(1)
    request(url(:new_staff_member)).body.to_s.should =~ /Not Privileged/ 
      request(url(:edit_staff_member, @staff.id)).body.to_s.should =~ /Not Privileged/
      #    request(url(:delete_staff_member, @staff.id)).body.to_s.should =~ /Not Privileged/

      @branch = Branch.get(1)
    request(url(:new_branch)).body.to_s.should =~ /Not Privileged/ 
      request(url(:edit_branch, @branch.id)).body.to_s.should =~ /Not Privileged/ 
      #    request(url(:delete_branch, @branch.id)).body.to_s.should =~ /Not Privileged/

      @center = Center.get(1)
    request(url(:new_branch_center, @branch.id)).body.to_s.should =~ /Not Privileged/ 
      request(url(:edit_branch_center, @branch.id, @center.id)).body.to_s.should =~ /Not Privileged/

      @client = Client.get(1)
    request(url(:new_branch_center_client, @branch.id, @center.id)).body.to_s.should =~ /Not Privileged/ 
      request(url(:edit_branch_center_client, @branch.id, @center.id, @client.id)).body.to_s.should =~ /Not Privileged/ 

      @loan_product = LoanProduct.get(2)

    @loan = Loan.new(:amount => @loan_product.min_amount, :interest_rate => @loan_product.min_interest_rate/100.0, :installment_frequency => :weekly, :number_of_installments => @loan_product.min_number_of_installments, :scheduled_first_payment_date => Date.today, :applied_on => Date.today-7, :applied_by => @staff, :scheduled_disbursal_date => Date.today-7, :client => @client, :loan_product => @loan_product)
    if @loan.save
      request(url(:new_branch_center_client_loan, @branch.id, @center.id, @client.id)).body.to_s.should =~ /Not Privileged/ 
        request(url(:edit_branch_center_client_loan, @branch.id, @center.id, @client.id, @loan.id)).body.to_s.should =~ /Not Privileged/
        request(url(:delete_branch_center_client_loan, @branch.id, @center.id, @client.id, @loan.id)).body.to_s.should =~ /Not Privileged/ 
    else
      @loan.errors
    end

    @user = User.get(1)
    request(url(:users)).body.to_s.should  =~ /Not Privileged/ 
      #    request(url(:users, @user.id)).body.to_s.should  =~ /Not Privileged/ 
      request(url(:new_user)).body.to_s.should  =~ /Not Privileged/ 
      request(url(:edit_user, @user.id)).body.to_s.should  =~ /Not Privileged/ 
      request(url(:delete_user, @user.id)).body.to_s.should  =~ /Not Privileged/
  end

  it "should check center manager credentials" do
    response = request url(:perform_login), :method => "PUT", :params => {:login => 'center', :password => 'center'}
    response.should redirect 
    request("/branches").should be_successful 

    @user = User.get(1)
    response = request(url(:new_user)).body.to_s.should =~ /Not Privileged/
      request(url(:edit_user, @user.id)).body.to_s.should =~ /Not Privileged/
      request(url(:delete_user, @user.id)).body.to_s.should =~ /Not Privileged/
      request(resource(:staff_members, :new)).body.to_s.should  =~ /Not Privileged/

      @staff = User.first(:login => 'center').staff_member
    @other_staff = (StaffMember.all-[@staff]).first
    request(url(:edit_staff_member, @other_staff.id)).body.to_s.should =~ /Not Privileged/
      #    request(url(:delete_staff_member, @staff.id)).body.to_s.should =~ /Not Privileged/                                                                     
      @branch = @staff.centers.branches.first
    request(url(:new_branch)).body.to_s.should =~ /Not Privileged/
      request(url(:edit_branch, @branch.id)).body.to_s.should =~ /Not Privileged/

      @center = @staff.centers.first
    request(resource(@branch, :centers, :new)).should_not be_successful
    request(resource(@branch, @center, :edit)).should be_successful
    #    request(url(:delete_branch_center, @branch.id, @center.id)).should be_successful                                                                       
    @client = @center.clients.first
    #request(resource(@branch, @center, :clients, :new)).should be_successful
    request(resource(@branch, @center, @client, :edit)).should be_successful
    #    request(url(:delete_branch_center_client, @branch.id, @center.id, @client.id)).should be_successful                                                    
    @loan_product = LoanProduct.get(2)
    @loan = Loan.new(:amount => @loan_product.min_amount, :interest_rate => @loan_product.min_interest_rate/100.0, :installment_frequency => :weekly, :number_of_installments => @loan_product.min_number_of_installments, :scheduled_first_payment_date => Date.today, :applied_on => Date.today-7, :applied_by => @staff, :scheduled_disbursal_date => Date.today-7, :client => @client, :loan_product => @loan_product)
    if @loan.save
      request(url(:branch_center_client_loan_payments, @branch.id, @center.id, @client.id, @loan.id)).should be_successful
      request(url(:new_branch_center_client_loan, @branch.id, @center.id, @client.id)).should be_successful
      request(url(:edit_branch_center_client_loan, @branch.id, @center.id, @client.id, @loan.id)).should be_successful
      #    request(url(:delete_branch_center_client_loan, @branch.id, @center.id, @client.id, @loan.id)).should be_successful                               
    else
      @loan.errors
    end
  end

  it "should check branch manager cerdentials" do
    response = request url(:perform_login), :method => "PUT", :params => {:login => 'branch', :password => 'branch'}
    response.should redirect 
    request("/branches").should be_successful

    @user = User.get(1)
    response = request(url(:new_user)).body.to_s.should =~ /Not Privileged/
      request(url(:edit_user, @user.id)).body.to_s.should =~ /Not Privileged/
      request(url(:delete_user, @user.id)).body.to_s.should =~ /Not Privileged/

      @staff = User.first(:login => "branch").staff_member
    request(url(:new_staff_member)).should_not be_successful
    request(url(:edit_staff_member, @staff.id)).should be_successful
    #    request(url(:delete_staff_member, @staff.id)).body.to_s.should =~ /Not Privileged/       

    @branch = @staff.branches.first
    request(url(:new_branch)).should_not be_successful
    request(url(:edit_branch, @branch.id)).should be_successful
    #    request(url(:delete_branch, @branch.id)).should be_successful #FIX THIS - no template error should be caught                                           
    @center = @branch.centers.first
    request(url(:new_branch_center, @branch.id)).should be_successful
    request(url(:edit_branch_center, @branch.id, @center.id)).should be_successful
    #    request(url(:delete_branch_center, @branch.id, @center.id)).should be_successful                                                                       
    @client = @center.clients.first
    request(url(:new_branch_center_client, @branch.id, @center.id)).should be_successful
    request(url(:edit_branch_center_client, @branch.id, @center.id, @client.id)).should be_successful
    #    request(url(:delete_branch_center_client, @branch.id, @center.id, @client.id)).should be_successful                                                    
    @loan_product = LoanProduct.get(2)

    @funder = Funder.new(:name => "FWWB")
    @funder.save
    @funder.should be_valid

    @funding_line = FundingLine.new(:amount => 10_000_000, :interest_rate => 0.15, :purpose => "for women", :disbursal_date => "2006-02-02", :first_payment_date => "2007-05-05", :last_payment_date => "2009-03-03")
    @funding_line.funder = @funder
    @funding_line.save
    @funding_line.should be_valid

    @loan = Loan.new(:amount => @loan_product.min_amount, :interest_rate => @loan_product.min_interest_rate/100.0, :installment_frequency => :weekly, :number_of_installments => @loan_product.min_number_of_installments, :scheduled_first_payment_date => Date.today, :applied_on => Date.today-7, :applied_by => @staff, :scheduled_disbursal_date => Date.today-7, :client => @client, :loan_product => @loan_product, :funding_line => @funding_line)
    @loan.should be_valid
    if @loan.save
      request(url(:branch_center_client_loan_payments, @branch.id, @center.id, @client.id, @loan.id)).should be_successful
      request(url(:new_branch_center_client_loan, @branch.id, @center.id, @client.id)).should be_successful
      request(url(:edit_branch_center_client_loan, @branch.id, @center.id, @client.id, @loan.id)).should be_successful
      #    request(url(:delete_branch_center_client_loan, @branch.id, @center.id, @client.id, @loan.id)).should be_successful                               
    else
      @loan.errors
    end
  end

  it "should check data_entry_operator credentials" do
    response = request url(:perform_login), :method => "PUT", :params => {:login => 'data', :password => 'entry1'}
    response.should redirect
    request("/branches").should_not be_successful
    @user = User.get(1)
    response = request(url(:new_user)).body.to_s.should =~ /Not Privileged/ 
      request(url(:edit_user, @user.id)).body.to_s.should =~ /Not Privileged/ 
      request(url(:delete_user, @user.id)).body.to_s.should =~ /Not Privileged/ 

      @staff = StaffMember.get(1)
    request(url(:new_staff_member)).body.to_s.should =~ /Not Privileged/ 
      request(url(:edit_staff_member, @staff.id)).body.to_s.should =~ /Not Privileged/
      #    request(url(:delete_staff_member, @staff.id)).body.to_s.should =~ /Not Privileged/

      @branch = Branch.get(1)
    request(url(:new_branch)).body.to_s.should =~ /Not Privileged/ 
      request(url(:edit_branch, @branch.id)).body.to_s.should =~ /Not Privileged/ 
      request(url(:delete_branch, @branch.id)).body.to_s.should =~ /Not Privileged/

      @center = Center.get(1)
    request(url(:new_branch_center, @branch.id)).body.to_s.should =~ /Not Privileged/ 
      request(url(:edit_branch_center, @branch.id, @center.id)).body.to_s.should =~ /Not Privileged/
      request(url(:delete_branch_center, @branch.id, @center.id)).body.to_s.should =~ /Not Privileged/

      @client = Client.get(1)
    request(resource(@branch, @center)).body.to_s.should =~ /Not Privileged/ 
      request(url(:edit_branch_center_client, @branch.id, @center.id, @client.id)).should be_successful
    @loan_product = LoanProduct.get(2)
    @loan = Loan.new(:amount => @loan_product.min_amount, :interest_rate => @loan_product.min_interest_rate/100.0, :installment_frequency => :weekly, :number_of_installments => @loan_product.min_number_of_installments, :scheduled_first_payment_date => Date.today, :applied_on => Date.today-7, :applied_by => @staff, :scheduled_disbursal_date => Date.today-7, :client => @client, :loan_product => @loan_product)
    if @loan.save
      request(url(:new_branch_center_client_loan, @branch.id, @center.id, @client.id)).should be_successful
      request(url(:edit_branch_center_client_loan, @branch.id, @center.id, @client.id, @loan.id)).should be_successful
      request(url(:delete_branch_center_client_loan, @branch.id, @center.id, @client.id, @loan.id)).should be_successful
    else
      @loan.errors
    end

    @user = User.get(1)
    request(url(:users)).body.to_s.should  =~ /Not Privileged/ 
      #    request(url(:users, @user.id)).body.to_s.should be_successful
      request(url(:new_user)).body.to_s.should  =~ /Not Privileged/ 
      request(url(:edit_user, @user.id)).body.to_s.should  =~ /Not Privileged/ 
      #    request(url(:enter_loans)).status.should == 200
      #    request(url(:enter_payments)).status.should == 200
      #    request(url(:data_entry)).status.should == 200
      #    request(url(:enter_clients)).status.should == 200
      #    request(url(:enter_attendancy)).status.should == 200

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
    #    request(url(:delete_staff_member, @staff.id)).should be_successful    # NO action in controller

    @branch = Branch.get(1)
    request(url(:new_branch)).should be_successful
    request(url(:edit_branch, @branch.id)).should be_successful 
    #    request(url(:delete_branch, @branch.id)).should be_successful #FIX THIS - no template error should be caught

    @center = Center.get(1)
    request(url(:new_branch_center, @branch.id)).should be_successful
    request(url(:edit_branch_center, @branch.id, @center.id)).should be_successful 
    #    request(url(:delete_branch_center, @branch.id, @center.id)).should be_successful 

    @client = Client.get(1)
    request(url(:new_branch_center_client, @branch.id, @center.id)).should be_successful 
    request(url(:edit_branch_center_client, @branch.id, @center.id, @client.id)).should be_successful 
    #    request(url(:delete_branch_center_client, @branch.id, @center.id, @client.id)).should be_successful 
    @loan_product = LoanProduct.get(2)
    @loan = Loan.new(:amount => @loan_product.min_amount, :interest_rate => @loan_product.min_interest_rate/100.0, :installment_frequency => :weekly, :number_of_installments => @loan_product.min_number_of_installments, :scheduled_first_payment_date => Date.today, :applied_on => Date.today-7, :applied_by => @staff, :scheduled_disbursal_date => Date.today-7, :client => @client, :loan_product => @loan_product)
    if @loan.save
      request(url(:branch_center_client_loan_payments, @branch.id, @center.id, @client.id, @loan.id)).should be_successful 
      request(url(:new_branch_center_client_loan, @branch.id, @center.id, @client.id)).should be_successful 
      request(url(:edit_branch_center_client_loan, @branch.id, @center.id, @client.id, @loan.id)).should be_successful
      #    request(url(:delete_branch_center_client_loan, @branch.id, @center.id, @client.id, @loan.id)).should be_successful 
    else
      @loan.errors
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
    #    request(url(:delete_staff_member, @staff.id)).should be_successful    # NO action in controller

    @branch = Branch.get(1)
    request(url(:new_branch)).should be_successful
    request(url(:edit_branch, @branch.id)).should be_successful 
    #    request(url(:delete_branch, @branch.id)).should be_successful #FIX THIS - no template error should be caught

    @center = Center.get(1)
    request(url(:new_branch_center, @branch.id)).should be_successful
    request(url(:edit_branch_center, @branch.id, @center.id)).should be_successful 
    #    request(url(:delete_branch_center, @branch.id, @center.id)).should be_successful 

    @client = Client.get(1)
    request(url(:new_branch_center_client, @branch.id, @center.id)).should be_successful 
    request(url(:edit_branch_center_client, @branch.id, @center.id, @client.id)).should be_successful 
    #    request(url(:delete_branch_center_client, @branch.id, @center.id, @client.id)).should be_successful 
    @loan_product = LoanProduct.get(2)

    @funder = Funder.new(:name => "FWWB")
    @funder.save
    @funder.should be_valid

    @funding_line = FundingLine.new(:amount => 10_000_000, :interest_rate => 0.15, :purpose => "for women", :disbursal_date => "2006-02-02", :first_payment_date => "2007-05-05", :last_payment_date => "2009-03-03")
    @funding_line.funder = @funder
    @funding_line.save
    @funding_line.should be_valid

    @loan = Loan.new(:amount => @loan_product.min_amount, :interest_rate => @loan_product.min_interest_rate/100.0, :installment_frequency => :weekly, :number_of_installments => @loan_product.min_number_of_installments, :scheduled_first_payment_date => Date.today, :applied_on => Date.today-7, :applied_by => @staff, :scheduled_disbursal_date => Date.today-7, :client => @client, :loan_product => @loan_product, :funding_line => @funding_line)
    @loan.should be_valid   
    if @loan.save
      request(url(:branch_center_client_loan_payments, @branch.id, @center.id, @client.id, @loan.id)).should be_successful 
      request(url(:new_branch_center_client_loan, @branch.id, @center.id, @client.id)).should be_successful 
      request(url(:edit_branch_center_client_loan, @branch.id, @center.id, @client.id, @loan.id)).should be_successful
      #    request(url(:delete_branch_center_client_loan, @branch.id, @center.id, @client.id, @loan.id)).should be_successful 
    else
      @loan.errors
    end
  end
end
