require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')

def load_fixtures(*files)
  DataMapper.auto_migrate! if Merb.orm == :datamapper
  files.each do |name|
    klass = Kernel::const_get(name.to_s.singularize.camel_case)
    yml_file =  "spec/fixtures/#{name}.yml"
    puts "\nLoading: #{yml_file}"
    entries = YAML::load_file(Merb.root / yml_file)
    entries.each do |name, entry|
      k = klass::new(entry)
      k.history_disabled = true if k.class == Loan  # do not update the hisotry for loans
      unless k.save
        puts "Validation errors saving a #{klass} (##{k.id}):"
        p k.errors
      end
    end
  end
end

describe "Controllers "  do
  before(:all) do
    load_fixtures :users, :staff_members, :branches, :centers, :clients #, :loans  #, :payments
    @u_data_entry = User.new(:login => 'data', :password => 'entry', :password_confirmation => 'entry', :data_entry_operator => true)
    @u_data_entry.save
    @u_read_only = User.new(:login => 'read', :password => 'only', :password_confirmation => 'only', :read_only_user => true)
    @u_read_only.save
    @u_mis_manager = User.new(:login => 'mis', :password => 'manager', :password_confirmation => 'manager', :mis_manager => true)
    @u_mis_manager.save
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
    request(url(:new_branch_center_client, @branch.id, @center.id)).body.to_s.should =~ /Not Privileged/ 
    request(url(:edit_branch_center_client, @branch.id, @center.id, @client.id)).body.to_s.should =~ /Not Privileged/ 
    request(url(:delete_branch_center_client, @branch.id, @center.id, @client.id)).body.to_s.should =~ /Not Privileged/ 

    @loan = Loan.new(:amount => 1000, :interest_rate => 0.2, :installment_frequency => :weekly, :number_of_installments => 30, :scheduled_first_payment_date => "2000-12-06", :applied_on => "2000-02-01", :applied_by => @staff, :scheduled_disbursal_date => "2000-06-13", :client => @client)
    if @loan.save
      request(url(:new_branch_center_client_loan, @branch.id, @center.id, @client.id)).body.to_s.should =~ /Not Privileged/ 
      request(url(:edit_branch_center_client_loan, @branch.id, @center.id, @client.id, @loan.id)).body.to_s.should =~ /Not Privileged/ 
      request(url(:delete_branch_center_client_loan, @branch.id, @center.id, @client.id, @loan.id)).body.to_s.should =~ /Not Privileged/ 
    else
      p [@loan, @loan.errors]
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
    request("/branches").should be_successful
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
    request(url(:new_branch_center_client, @branch.id, @center.id)).body.to_s.should =~ /Not Privileged/ 
    request(url(:edit_branch_center_client, @branch.id, @center.id, @client.id)).body.to_s.should =~ /Not Privileged/ 
    request(url(:delete_branch_center_client, @branch.id, @center.id, @client.id)).body.to_s.should =~ /Not Privileged/ 

    @loan = Loan.new(:amount => 1000, :interest_rate => 0.2, :installment_frequency => :weekly, :number_of_installments => 30, :scheduled_first_payment_date => "2000-12-06", :applied_on => "2000-02-01", :applied_by => @staff, :scheduled_disbursal_date => "2000-06-13", :client => @client)
    if @loan.save
      request(url(:new_branch_center_client_loan, @branch.id, @center.id, @client.id)).body.to_s.should =~ /Not Privileged/ 
      request(url(:edit_branch_center_client_loan, @branch.id, @center.id, @client.id, @loan.id)).body.to_s.should =~ /Not Privileged/ 
      request(url(:delete_branch_center_client_loan, @branch.id, @center.id, @client.id, @loan.id)).body.to_s.should =~ /Not Privileged/ 
    else
      p [@loan, @loan.errors]
    end

    @user = User.get(1)
    request(url(:users)).body.to_s.should  =~ /Not Privileged/ 
#    request(url(:users, @user.id)).body.to_s.should be_successful
    request(url(:new_user)).body.to_s.should  =~ /Not Privileged/ 
    request(url(:edit_user, @user.id)).body.to_s.should  =~ /Not Privileged/ 
    request(url(:delete_user, @user.id)).body.to_s.should  =~ /Not Privileged/ 

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

    @loan = Loan.new(:amount => 1000, :interest_rate => 0.2, :installment_frequency => :weekly, :number_of_installments => 30, :scheduled_first_payment_date => "2000-12-06", :applied_on => "2000-02-01", :applied_by => @staff, :scheduled_disbursal_date => "2000-06-13", :client => @client)
    if @loan.save
      request(url(:branch_center_client_loan_payments, @branch.id, @center.id, @client.id, @loan.id)).should be_successful 
      request(url(:new_branch_center_client_loan, @branch.id, @center.id, @client.id)).should be_successful 
      request(url(:edit_branch_center_client_loan, @branch.id, @center.id, @client.id, @loan.id)).should be_successful
      #    request(url(:delete_branch_center_client_loan, @branch.id, @center.id, @client.id, @loan.id)).should be_successful 
    else
      p [@loan, @loan.errors]
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

    @loan = Loan.new(:amount => 1000, :interest_rate => 0.2, :installment_frequency => :weekly, :number_of_installments => 30, :scheduled_first_payment_date => "2000-12-06", :applied_on => "2000-02-01", :applied_by => @staff, :scheduled_disbursal_date => "2000-06-13", :client => @client)
    if @loan.save
      request(url(:branch_center_client_loan_payments, @branch.id, @center.id, @client.id, @loan.id)).should be_successful 
      request(url(:new_branch_center_client_loan, @branch.id, @center.id, @client.id)).should be_successful 
      request(url(:edit_branch_center_client_loan, @branch.id, @center.id, @client.id, @loan.id)).should be_successful
      #    request(url(:delete_branch_center_client_loan, @branch.id, @center.id, @client.id, @loan.id)).should be_successful 
    else
      p [@loan, @loan.errors]
    end
  end
end
