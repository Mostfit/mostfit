require File.join( File.dirname(__FILE__), '..', "spec_helper" )


describe User do
  before(:all) do
    load_fixtures :users, :staff_members, :regions, :areas, :branches, :centers, :client_types, :clients, :loan_products, :funders, :funding_lines, :loans
  end

  before(:each) do
    @user = User.new(:id => 10, :login=>"sparsh", :created_at => "2002-11-23", :updated_at => "2003-11-23", :role => :admin)
  end
  it "should not be valid with name shorter than 3 characters" do
    @user.login = "ok"
    @user.should_not be_valid
  end

  it "should not have a nil login " do
    @user.login=nil
    @user.should_not be_valid
  end

  it "should be return for admin? if admin value set to true" do
    @user.admin?.should==true
  end

  it "should be created before it is updated" do
    @user.created_at="23-11-2006"
    @user.updated_at="23-3-2005"
    @user.should_not be_valid
  end

  it "should have a login name beginning with numbers, aplphabets and underscores " do
    @user.login="#kate"
    @user.should_not be_valid	
  end

  it "should have a role" do
    @user.role = nil
    @user.should_not be_valid
  end

  it "should give access to admin for all models" do
    @user.can_access?({:action =>"index", :controller =>"verifications"}).should be_true
    @user.can_access?({:action =>"index", :controller =>"verifications"}, {:model => "clients", :action => "index", :controller => "verifications"}).should be_true
    @user.can_access?({:action =>"index", :controller =>"verifications"}, {:model => "loans", :action => "index", :controller => "verifications"}).should be_true
    @user.can_access?({:action =>"index", :controller =>"verifications"}, {:model => "payments", :action => "index", :controller => "verifications"}).should be_true

    @user.can_access?({:action =>"index", :controller =>"documents"}).should be_true
    @user.can_access?({:action =>"index", :controller =>"accounts"}).should be_true
    @user.can_access?({:action =>"index", :controller =>"browse"}).should be_true
    @user.can_access?({:action =>"index", :namespace =>"data_entry", :controller=>"index"}).should be_true
    @user.can_access?({:action =>"index", :controller =>"admin"}).should be_true
    @user.can_access?({:action =>"index", :controller =>"dashboard"})
    @user.can_access?({:action =>"index", :controller =>"reports"}).should be_true
    @user.can_access?({:action =>"hq_tab", :controller =>"browse"}).should be_true
    @user.can_access?({:action => "branch", :branch_id => nil, :id=>"centers", :controller=>"dashboard"}).should be_true
    @user.can_access?({:action => "index", :controller => "branches"}).should be_true
    #branch access
    Branch.all.each{|branch|
      @user.can_access?({:action => "show", :id => branch.id, :controller => "branches"}).should be_true
    }
    #branch creation
    @user.can_access?({:action => "create", :controller => "branches"}, 
                      {:branch => {:name => "Bhopal 1", :address => "dzv fsb g", :contact_number => "90000000000", :manager_staff_id => 1, :code => "MPBPL01", :landmark => "New Bhopal", 
                          :creation_date => "27-11-2010", :area_id => 1}}).should be_true

    #center access
    Center.all.each{|center|
      @user.can_access?({:action => "show", :id => center.id, :controller => "centers", :branch_id => center.branch_id}).should be_true
    }
    #center creation
    @user.can_access?({:action => "create", :controller => "centers"}, 
                      {:center => {:name => "Center 1", :address => "dzv fsb g", :contact_number => "90000000000", :manager_staff_id => 1, :code => "MPBPL0101", :landmark => "New Bhopal", 
                          :creation_date => "27-11-2010", :meeting_time_hours => 8, :branch_id => 3, :meeting_day => "monday", :meeting_time_minutes => 30}}).should be_true

    #client access
    Client.all.each{|client|
      @user.can_access?({:action => "show", :id => client.id, :controller => "clients", :branch_id => client.center.branch_id, :center_id => client.center_id}).should be_true
    }
    #client creation
    @user.can_access?({:action => "create", :controller => "clients"}, 
                      {:client => {:center_id => 1, :name => "piyush", :reference => "MPBPL0107012", :address => "", :date_of_birth => "03-03-1991", :client_type_id => 1}}).should be_true

    #loan access
    Loan.all.each{|loan|
      @user.can_access?({:action => "show", :id => loan.id, :controller => "loans"}).should be_true
    }
    #loans create
    @user.can_access?({:action => "create", :controller => "loans", :branch_id => 1, :center_id => 1, :client_id => 1, :loan_type => :default_loan}, 
                      {:default_loan => {:loan_product_id => 1, :amount => 10000, :interest => 10, :applied_on => "03-03-2010", :scheduled_disbursement_date => "03-03-2010",
                          :scheduled_first_payment_date => "10-03-2010"}}).should be_true
 
    # admin stuff
    @user.can_access?({:action => "index", :controller => "admin"}).should be_true
    @user.can_access?({:action => "edit", :controller => "admin"}).should be_true
    @user.can_access?({:action => "index", :controller => "holidays"}).should be_true
    @user.can_access?({:action => "create", :controller => "holidays"}).should be_true
    @user.can_access?({:action => "update", :controller => "holidays"}).should be_true

    @user.can_access?({:action => "index", :controller => "regions"}).should be_true
    @user.can_access?({:action => "create", :controller => "regions"}).should be_true
    @user.can_access?({:action => "update", :controller => "regions"}).should be_true

    @user.can_access?({:action => "index", :controller => "areas"}).should be_true
    @user.can_access?({:action => "create", :controller => "areas"}).should be_true
    @user.can_access?({:action => "update", :controller => "areas"}).should be_true

    @user.can_access?({:action => "index", :controller => "staff_members"}).should be_true
    @user.can_access?({:action => "create", :controller => "staff_members"}).should be_true
    @user.can_access?({:action => "update", :controller => "staff_members"}).should be_true

    @user.can_access?({:action => "index", :controller => "users"}).should be_true
    @user.can_access?({:action => "update", :controller => "users"}).should be_true

    @user.can_access?({:action => "index", :controller => "funders"}).should be_true
    @user.can_access?({:action => "update", :controller => "funders"}).should be_true

    @user.can_access?({:action => "index", :controller => "funding_lines", :funder_id => 1}).should be_true
    @user.can_access?({:action => "update", :controller => "funding_lines", :funder_id => 1}).should be_true

    @user.can_access?({:action => "index", :controller => "portfolios", :funder_id => 1}).should be_true
    @user.can_access?({:action => "update", :controller => "portfolios", :funder_id => 1}).should be_true

    @user.can_access?({:action => "index", :controller => "rules"}).should be_true
    @user.can_access?({:action => "create", :controller => "rules"}).should be_true
    @user.can_access?({:action => "update", :controller => "rules"}).should be_true

    @user.can_access?({:action => "index", :controller => "targets"}).should be_true
    @user.can_access?({:action => "create", :controller => "targets"}).should be_true
    @user.can_access?({:action => "update", :controller => "targets"}).should be_true

    @user.can_access?({:action => "index", :controller => "fees"}).should be_true
    @user.can_access?({:action => "create", :controller => "fees"}).should be_true
    @user.can_access?({:action => "update", :controller => "fees"}).should be_true

    @user.can_access?({:action => "index", :controller => "loan_products"}).should be_true
    @user.can_access?({:action => "create", :controller => "loan_products"}).should be_true
    @user.can_access?({:action => "update", :controller => "loan_products"}).should be_true

    @user.can_access?({:action => "index", :controller => "insurance_companies"}).should be_true
    @user.can_access?({:action => "create", :controller => "insurance_companies"}).should be_true
    @user.can_access?({:action => "update", :controller => "insurance_companies"}).should be_true

    @user.can_access?({:action => "index", :controller => "accounts"}).should be_true
    @user.can_access?({:action => "create", :controller => "accounts"}).should be_true
    @user.can_access?({:action => "update", :controller => "accounts"}).should be_true

    @user.can_access?({:action => "index", :controller => "client_types"}).should be_true
    @user.can_access?({:action => "create", :controller => "client_types"}).should be_true
    @user.can_access?({:action => "update", :controller => "client_types"}).should be_true

    @user.can_access?({:action => "index", :controller => "occupations"}).should be_true
    @user.can_access?({:action => "create", :controller => "occupations"}).should be_true
    @user.can_access?({:action => "update", :controller => "occupations"}).should be_true

    @user.can_access?({:action => "index", :controller => "loan_utilizations"}).should be_true
    @user.can_access?({:action => "create", :controller => "loan_utilizations"}).should be_true
    @user.can_access?({:action => "update", :controller => "loan_utilizations"}).should be_true

    @user.can_access?({:action => "index", :controller => "document_types"}).should be_true
    @user.can_access?({:action => "create", :controller => "document_types"}).should be_true
    @user.can_access?({:action => "update", :controller => "document_types"}).should be_true

    @user.can_access?({:action => "index", :controller => "audit_items"}).should be_true
    @user.can_access?({:action => "create", :controller => "audit_items"}).should be_true
    @user.can_access?({:action => "update", :controller => "audit_items"}).should be_true

    @user.can_access?({:action => "show", :id => "show", :controller => "audit_trails"}).should be_true
    @user.can_access?({:action => "upload", :controller => "admin"}).should be_true
    @user.can_access?({:action => "download", :controller => "admin"}).should be_true
    @user.can_access?({:action => "dirty_loans", :controller => "admin"}).should be_true
    @user.can_access?({:action => "index", :controller => "dashboard"}).should be_true
    @user.can_access?({:action => "index", :controller => "reports"}).should be_true
  end

  it "should give access to mis manager for accessible models" do
    @user.role = :mis_manager
    #verifications
    @user.can_access?({:action =>"index", :controller =>"verifications"}).should be_true
    @user.can_access?({:action =>"index", :controller =>"verifications"}, {:model => "clients", :action => "index", :controller => "verifications"}).should be_true
    @user.can_access?({:action =>"index", :controller =>"verifications"}, {:model => "loans", :action => "index", :controller => "verifications"}).should be_true
    @user.can_access?({:action =>"index", :controller =>"verifications"}, {:model => "payments", :action => "index", :controller => "verifications"}).should be_true
    #browse page stuff
    @user.can_access?({:action =>"index", :controller =>"documents"}).should be_true
    @user.can_access?({:action =>"index", :controller =>"accounts"}).should be_true
    @user.can_access?({:action =>"index", :controller =>"browse"}).should be_true
    @user.can_access?({:action =>"index", :namespace =>"data_entry", :controller=>"index"}).should be_true
    @user.can_access?({:action =>"hq_tab", :controller =>"browse"}).should be_true
    @user.can_access?({:action => "branch", :branch_id => nil, :id=>"centers", :controller=>"dashboard"}).should be_true
    @user.can_access?({:action => "index", :controller => "branches"}).should be_true
    #branch access
    Branch.all.each{|branch|
      @user.can_access?({:action => "show", :id => branch.id, :controller => "branches"}).should be_true
    }
    #branch creation
    @user.can_access?({:action => "create", :controller => "branches"}, 
                      {:branch => {:name => "Bhopal 1", :address => "dzv fsb g", :contact_number => "90000000000", :manager_staff_id => 1, :code => "MPBPL01", :landmark => "New Bhopal", 
                          :creation_date => "27-11-2010", :area_id => 1}}).should be_true

    #center access
    Center.all.each{|center|
      @user.can_access?({:action => "show", :id => center.id, :controller => "centers", :branch_id => center.branch_id}).should be_true
    }
    #center creation
    @user.can_access?({:action => "create", :controller => "centers"}, 
                      {:center => {:name => "Center 1", :address => "dzv fsb g", :contact_number => "90000000000", :manager_staff_id => 1, :code => "MPBPL0101", :landmark => "New Bhopal", 
                          :creation_date => "27-11-2010", :meeting_time_hours => 8, :branch_id => 3, :meeting_day => "monday", :meeting_time_minutes => 30}}).should be_true

    #client access
    Client.all.each{|client|
      @user.can_access?({:action => "show", :id => client.id, :controller => "clients", :branch_id => client.center.branch_id, :center_id => client.center_id}).should be_true
    }
    #client creation
    @user.can_access?({:action => "create", :controller => "clients"}, 
                      {:client => {:center_id => 1, :name => "piyush", :reference => "MPBPL0107012", :address => "", :date_of_birth => "03-03-1991", :client_type_id => 1}}).should be_true

    #loan access
    Loan.all.each{|loan|
      @user.can_access?({:action => "show", :id => loan.id, :controller => "loans"}).should be_true
    }
    #loans create
    @user.can_access?({:action => "create", :controller => "loans", :branch_id => 1, :center_id => 1, :client_id => 1, :loan_type => :default_loan}, 
                      {:default_loan => {:loan_product_id => 1, :amount => 10000, :interest => 10, :applied_on => "03-03-2010", :scheduled_disbursement_date => "03-03-2010",
                          :scheduled_first_payment_date => "10-03-2010"}}).should be_true

    # admin & manage stuff
    @user.can_access?({:action => "index", :controller => "admin"}).should be_false
    @user.can_access?({:action => "edit", :controller => "admin"}).should be_false

    @user.can_access?({:action => "index", :controller => "holidays"}).should be_true
    @user.can_access?({:action => "create", :controller => "holidays"}).should be_true
    @user.can_access?({:action => "update", :controller => "holidays"}).should be_true

    @user.can_access?({:action => "index", :controller => "regions"}).should be_true
    @user.can_access?({:action => "create", :controller => "regions"}).should be_true
    @user.can_access?({:action => "update", :controller => "regions"}).should be_true

    @user.can_access?({:action => "index", :controller => "areas"}).should be_true
    @user.can_access?({:action => "create", :controller => "areas"}).should be_true
    @user.can_access?({:action => "update", :controller => "areas"}).should be_true

    @user.can_access?({:action => "index", :controller => "staff_members"}).should be_true
    @user.can_access?({:action => "create", :controller => "staff_members"}).should be_true
    @user.can_access?({:action => "update", :controller => "staff_members"}).should be_true

    @user.can_access?({:action => "index", :controller => "users"}).should be_false
    @user.can_access?({:action => "update", :controller => "users"}).should be_false

    @user.can_access?({:action => "index", :controller => "funders"}).should be_true
    @user.can_access?({:action => "update", :controller => "funders"}).should be_true

    @user.can_access?({:action => "index", :controller => "funding_lines", :funder_id => 1}).should be_true
    @user.can_access?({:action => "update", :controller => "funding_lines", :funder_id => 1}).should be_true

    @user.can_access?({:action => "index", :controller => "portfolios", :funder_id => 1}).should be_true
    @user.can_access?({:action => "update", :controller => "portfolios", :funder_id => 1}).should be_true

    @user.can_access?({:action => "index", :controller => "rules"}).should be_true
    @user.can_access?({:action => "create", :controller => "rules"}).should be_true
    @user.can_access?({:action => "update", :controller => "rules"}).should be_true

    @user.can_access?({:action => "index", :controller => "targets"}).should be_true
    @user.can_access?({:action => "create", :controller => "targets"}).should be_true
    @user.can_access?({:action => "update", :controller => "targets"}).should be_true

    @user.can_access?({:action => "index", :controller => "fees"}).should be_true
    @user.can_access?({:action => "create", :controller => "fees"}).should be_true
    @user.can_access?({:action => "update", :controller => "fees"}).should be_true

    @user.can_access?({:action => "index", :controller => "loan_products"}).should be_true
    @user.can_access?({:action => "create", :controller => "loan_products"}).should be_true
    @user.can_access?({:action => "update", :controller => "loan_products"}).should be_true

    @user.can_access?({:action => "index", :controller => "insurance_companies"}).should be_true
    @user.can_access?({:action => "create", :controller => "insurance_companies"}).should be_true
    @user.can_access?({:action => "update", :controller => "insurance_companies"}).should be_true

    @user.can_access?({:action => "index", :controller => "accounts"}).should be_true
    @user.can_access?({:action => "create", :controller => "accounts"}).should be_true
    @user.can_access?({:action => "update", :controller => "accounts"}).should be_true

    @user.can_access?({:action => "index", :controller => "client_types"}).should be_true
    @user.can_access?({:action => "create", :controller => "client_types"}).should be_true
    @user.can_access?({:action => "update", :controller => "client_types"}).should be_true

    @user.can_access?({:action => "index", :controller => "occupations"}).should be_true
    @user.can_access?({:action => "create", :controller => "occupations"}).should be_true
    @user.can_access?({:action => "update", :controller => "occupations"}).should be_true

    @user.can_access?({:action => "index", :controller => "loan_utilizations"}).should be_true
    @user.can_access?({:action => "create", :controller => "loan_utilizations"}).should be_true
    @user.can_access?({:action => "update", :controller => "loan_utilizations"}).should be_true

    @user.can_access?({:action => "index", :controller => "document_types"}).should be_true
    @user.can_access?({:action => "create", :controller => "document_types"}).should be_true
    @user.can_access?({:action => "update", :controller => "document_types"}).should be_true

    @user.can_access?({:action => "index", :controller => "audit_items"}).should be_true
    @user.can_access?({:action => "create", :controller => "audit_items"}).should be_true
    @user.can_access?({:action => "update", :controller => "audit_items"}).should be_true

    # upload, download stuff
    @user.can_access?({:action => "upload", :controller => "admin"}).should be_false
    @user.can_access?({:action => "download", :controller => "admin"}).should be_false
    @user.can_access?({:action => "dirty_loans", :controller => "admin"}).should be_false
    @user.can_access?({:action => "index", :controller => "dashboard"}).should be_true
    @user.can_access?({:action => "index", :controller => "reports"}).should be_true
  end

  it "should give access to mis manager who is also a staff member to only his/her side of mostfit" do
    @user.role = :mis_manager
    @user.staff_member = Branch.first.manager
    @user.password = @user.password_confirmation = "mismanager"
    @user.save

    managed_branches     = @user.staff_member.branches
    non_managed_branches = Branch.all(:id.not => @user.staff_member.branches.map{|x| x.id})
    managed_centers      = managed_branches.centers
    non_managed_centers  = non_managed_branches.centers

    #verifications
    @user.can_access?({:action =>"index", :controller =>"verifications"}).should be_true
    @user.can_access?({:action =>"index", :controller =>"verifications"}, {:model => "clients", :action => "index", :controller => "verifications"}).should be_true
    @user.can_access?({:action =>"index", :controller =>"verifications"}, {:model => "loans", :action => "index", :controller => "verifications"}).should be_true
    @user.can_access?({:action =>"index", :controller =>"verifications"}, {:model => "payments", :action => "index", :controller => "verifications"}).should be_true
    #browse page stuff
    @user.can_access?({:action =>"index", :controller =>"documents"}).should be_true
    @user.can_access?({:action =>"index", :controller =>"accounts"}).should be_true
    @user.can_access?({:action =>"index", :controller =>"browse"}).should be_true
    @user.can_access?({:action =>"index", :namespace =>"data_entry", :controller=>"index"}).should be_true
    @user.can_access?({:action =>"hq_tab", :controller =>"browse"}).should be_true
    @user.can_access?({:action => "branch", :branch_id => nil, :id=>"centers", :controller=>"dashboard"}).should be_true
    @user.can_access?({:action => "index", :controller => "branches"}).should be_true
    #branch access
    managed_branches.each{|branch|
      @user.can_access?({:action => "show", :id => branch.id, :controller => "branches"}).should be_true
    }
    #branch creation
    @user.can_access?({:action => "create", :controller => "branches"}, 
                      {:branch => {:name => "Bhopal 1", :address => "dzv fsb g", :contact_number => "90000000000", :manager_staff_id => 1, :code => "MPBPL01", :landmark => "New Bhopal", 
                          :creation_date => "27-11-2010", :area_id => 1}}).should be_false
    non_managed_branches.each{|branch|
      @user.can_access?({:action => "show", :id => branch.id, :controller => "branches"}).should be_false
    }

    #center access
    managed_centers.each{|center|
      @user.can_access?({:action => "show", :id => center.id, :controller => "centers", :branch_id => center.branch_id}).should be_true
    }

    non_managed_centers.each{|center|
      @user.can_access?({:action => "show", :id => center.id, :controller => "centers", :branch_id => center.branch_id}).should be_false
    }
    #center creation
    @user.can_access?({:action => "create", :controller => "centers"}, 
                      {:center => {:name => "Center 1", :address => "dzv fsb g", :contact_number => "90000000000", :manager_staff_id => 1, :code => "MPBPL0101", :landmark => "New Bhopal", 
                          :creation_date => "27-11-2010", :meeting_time_hours => 8, :branch_id => 3, :meeting_day => "monday", :meeting_time_minutes => 30}}).should be_true

    #client access
    managed_centers.clients.each{|client|
      @user.can_access?({:action => "show", :id => client.id, :controller => "clients", :branch_id => client.center.branch_id, :center_id => client.center_id}).should be_true
    }
    non_managed_centers.clients.each{|client|
      @user.can_access?({:action => "show", :id => client.id, :controller => "clients", :branch_id => client.center.branch_id, :center_id => client.center_id}).should be_false
    }

    #client creation
    @user.can_access?({:action => "create", :controller => "clients"}, 
                      {:client => {:center_id => 1, :name => "piyush", :reference => "MPBPL0107012", :address => "", :date_of_birth => "03-03-1991", :client_type_id => 1}}).should be_true

    #loan access
    managed_centers.clients.loans.each{|loan|
      @user.can_access?({:action => "show", :id => loan.id, :controller => "loans"}).should be_true
    }

    non_managed_centers.clients.each{|loan|
      @user.can_access?({:action => "show", :id => loan.id, :controller => "loans"}).should be_false
    }

    #loans create
    @user.can_access?({:action => "create", :controller => "loans", :branch_id => managed_branches.first.id, :center_id => managed_centers.first.id, 
                        :client_id => managed_centers.first.clients.first.id, :loan_type => :default_loan}, 
                      {:default_loan => {:loan_product_id => 1, :amount => 10000, :interest => 10, :applied_on => "03-03-2010", :scheduled_disbursement_date => "03-03-2010",
                          :scheduled_first_payment_date => "10-03-2010"}}).should be_true

    # admin & manage stuff
    @user.can_access?({:action => "index", :controller => "admin"}).should be_false
    @user.can_access?({:action => "edit", :controller => "admin"}).should be_false

    @user.can_access?({:action => "index", :controller => "holidays"}).should be_true
    @user.can_access?({:action => "create", :controller => "holidays"}).should be_true
    @user.can_access?({:action => "update", :controller => "holidays"}).should be_true

    @user.can_access?({:action => "index", :controller => "regions"}).should be_true
    @user.can_access?({:action => "create", :controller => "regions"}).should be_false
    @user.can_access?({:action => "update", :controller => "regions"}).should be_false

    @user.can_access?({:action => "index", :controller => "areas"}).should be_false
    @user.can_access?({:action => "create", :controller => "areas"}).should be_false
    @user.can_access?({:action => "update", :controller => "areas"}).should be_false

    @user.can_access?({:action => "index", :controller => "staff_members"}).should be_true
    @user.can_access?({:action => "create", :controller => "staff_members"}).should be_true
    @user.can_access?({:action => "update", :controller => "staff_members"}).should be_true

    @user.can_access?({:action => "index", :controller => "users"}).should be_false
    @user.can_access?({:action => "update", :controller => "users"}).should be_false

    @user.can_access?({:action => "index", :controller => "funders"}).should be_true
    @user.can_access?({:action => "update", :controller => "funders"}).should be_true

    @user.can_access?({:action => "index", :controller => "funding_lines", :funder_id => 1}).should be_true
    @user.can_access?({:action => "update", :controller => "funding_lines", :funder_id => 1}).should be_true

    @user.can_access?({:action => "index", :controller => "portfolios", :funder_id => 1}).should be_true
    @user.can_access?({:action => "update", :controller => "portfolios", :funder_id => 1}).should be_true

    @user.can_access?({:action => "index", :controller => "rules"}).should be_true
    @user.can_access?({:action => "create", :controller => "rules"}).should be_true
    @user.can_access?({:action => "update", :controller => "rules"}).should be_true

    @user.can_access?({:action => "index", :controller => "targets"}).should be_true
    @user.can_access?({:action => "create", :controller => "targets"}).should be_true
    @user.can_access?({:action => "update", :controller => "targets"}).should be_true

    @user.can_access?({:action => "index", :controller => "fees"}).should be_true
    @user.can_access?({:action => "create", :controller => "fees"}).should be_true
    @user.can_access?({:action => "update", :controller => "fees"}).should be_true

    @user.can_access?({:action => "index", :controller => "loan_products"}).should be_true
    @user.can_access?({:action => "create", :controller => "loan_products"}).should be_true
    @user.can_access?({:action => "update", :controller => "loan_products"}).should be_true

    @user.can_access?({:action => "index", :controller => "insurance_companies"}).should be_true
    @user.can_access?({:action => "create", :controller => "insurance_companies"}).should be_true
    @user.can_access?({:action => "update", :controller => "insurance_companies"}).should be_true

    @user.can_access?({:action => "index", :controller => "accounts"}).should be_true
    @user.can_access?({:action => "create", :controller => "accounts"}).should be_true
    @user.can_access?({:action => "update", :controller => "accounts"}).should be_true

    @user.can_access?({:action => "index", :controller => "client_types"}).should be_true
    @user.can_access?({:action => "create", :controller => "client_types"}).should be_true
    @user.can_access?({:action => "update", :controller => "client_types"}).should be_true

    @user.can_access?({:action => "index", :controller => "occupations"}).should be_true
    @user.can_access?({:action => "create", :controller => "occupations"}).should be_true
    @user.can_access?({:action => "update", :controller => "occupations"}).should be_true

    @user.can_access?({:action => "index", :controller => "loan_utilizations"}).should be_true
    @user.can_access?({:action => "create", :controller => "loan_utilizations"}).should be_true
    @user.can_access?({:action => "update", :controller => "loan_utilizations"}).should be_true

    @user.can_access?({:action => "index", :controller => "document_types"}).should be_true
    @user.can_access?({:action => "create", :controller => "document_types"}).should be_true
    @user.can_access?({:action => "update", :controller => "document_types"}).should be_true

    @user.can_access?({:action => "index", :controller => "audit_items"}).should be_true
    @user.can_access?({:action => "create", :controller => "audit_items"}).should be_true
    @user.can_access?({:action => "update", :controller => "audit_items"}).should be_true

    # upload, download stuff
    @user.can_access?({:action => "upload", :controller => "admin"}).should be_false
    @user.can_access?({:action => "download", :controller => "admin"}).should be_false
    @user.can_access?({:action => "dirty_loans", :controller => "admin"}).should be_false
    @user.can_access?({:action => "index", :controller => "dashboard"}).should be_true
    @user.can_access?({:action => "index", :controller => "reports"}).should be_true
  end

  it "should give access to branch manager as staff member for relevant stuff" do
    user = User.new(:login => "bm1",:created_at => "2002-11-23", :updated_at => "2003-11-23", :role => :staff_member, :password => "foobar", :password_confirmation => "foobar")
    user.staff_member = StaffMember.first
    user.save
    
    user.can_access?({:action =>"index", :controller =>"verifications"}).should be_false
    user.can_access?({:action =>"index", :controller =>"documents"}).should be_true
    user.can_access?({:action =>"index", :controller =>"accounts"}).should be_false
    user.can_access?({:action =>"index", :controller =>"browse"}).should be_true
    user.can_access?({:action =>"index", :namespace =>"data_entry", :controller => "index"}).should be_true
    user.can_access?({:action =>"hq_tab", :controller =>"browse"}).should be_true
    user.can_access?({:action => "index", :controller => "branches"}).should be_true
    #branch access
    user.staff_member.branches.each{|branch|
      user.can_access?({:action => "show", :id => branch.id, :controller => "branches"}).should be_true
    }
    #branch creation
    user.can_access?({:action => "create", :controller => "branches"}, 
                     {:branch => {:name => "Bhopal 1", :address => "dzv fsb g", :contact_number => "90000000000", :manager_staff_id => 1, :code => "MPBPL01", :landmark => "New Bhopal", 
                         :creation_date => "27-11-2010", :area_id => 1}}).should be_false
    #center access
    user.staff_member.branches.centers.each{|center|
      user.can_access?({:action => "show", :id => center.id, :controller => "centers", :branch_id => center.branch_id}).should be_true
    }
    #center creation
    managed_branches = user.staff_member.branches
    user.can_access?({:action => "create", :controller => "centers", :branch_id => managed_branches.first.id}, 
                     {:center => {
                         :name => "Center 1", :address => "dzv fsb g", :contact_number => "90000000000", :manager_staff_id => 1, :code => "MPBPL0101", :landmark => "New Bhopal", 
                         :creation_date => "27-11-2010", :meeting_time_hours => 8, :branch_id => managed_branches.first.id, :meeting_day => "monday", :meeting_time_minutes => 30}
                     }).should be_true

    non_managed_branches = Branch.all(:id.not => user.staff_member.branches.map{|x| x.id})
    user.can_access?({:action => "create", :controller => "centers"}, 
                     {:center => {:name => "Center 1", :address => "dzv fsb g", :contact_number => "90000000000", :manager_staff_id => 2, :code => "MPBPL0101", :landmark => "New Bhopal", 
                         :creation_date => "27-11-2010", :meeting_time_hours => 8, :branch_id => non_managed_branches.first.id, :meeting_day => "monday", 
                         :meeting_time_minutes => 30}}).should be_false

    #client access
    user.staff_member.branches.centers.clients.all.each{|client|
      user.can_access?({:action => "show", :id => client.id, :controller => "clients", :branch_id => client.center.branch_id, :center_id => client.center_id}).should be_true
    }
    #client creation
    user.can_access?({:action => "create", :controller => "clients"}, 
                      {:client => {
                         :center_id => managed_branches.centers.first.id, :name => "piyush", :reference => "MPBPL0107012", :address => "", :date_of_birth => "03-03-1991", 
                         :client_type_id => 1}
                     }).should be_true
    user.can_access?({:action => "create", :controller => "clients"}, 
                      {:client => {
                         :center_id => non_managed_branches.centers.first.id, :name => "piyush", :reference => "MPBPL0107012", :address => "", :date_of_birth => "03-03-1991", 
                         :client_type_id => 1}
                     }).should be_false
    #loan access
    user.staff_member.branches.centers.clients.loans.all.each{|loan|
      user.can_access?({:action => "show", :id => loan.id, :controller => "loans"}).should be_true
    }
    #loans create
    user.can_access?({:action => "create", :controller => "loans"}, 
                      {:default_loan => {:loan_product_id => 1, :amount => 10000, :interest => 10, :applied_on => "03-03-2010", :scheduled_disbursement_date => "03-03-2010",
                          :scheduled_first_payment_date => "10-03-2010", :client_id => managed_branches.centers.clients.first.id}, :loan_type => "DefaultLoan"}).should be_true
    # loan access should be denied for other branches
    user.can_access?({:action => "create", :controller => "loans"},
                      {:default_loan => {:loan_product_id => 1, :amount => 10000, :interest => 10, :applied_on => "03-03-2010", :scheduled_disbursement_date => "03-03-2010",
                          :scheduled_first_payment_date => "10-03-2010", :client_id => non_managed_branches.centers.clients.first.id}, :loan_type => "DefaultLoan"}).should be_false
    #deny access
    #branch access
    Branch.all(:manager.not => user.staff_member).each{|branch|
      user.can_access?({:action => "show", :id => branch.id, :controller => "branches"}).should be_false
    }
    #center access
    Branch.all(:manager.not => user.staff_member).centers(:manager.not => user.staff_member).each{|center|
      user.can_access?({:action => "show", :id => center.id, :controller => "centers", :branch_id => center.branch_id}).should be_false
    }
    #client access
    Branch.all(:manager.not => user.staff_member).centers(:manager.not => user.staff_member).clients.each{|client|
      user.can_access?({:action => "show", :id => client.id, :controller => "clients", :branch_id => client.center.branch_id, :center_id => client.center_id}).should be_false
    }
    #loan access
    Branch.all(:manager.not => user.staff_member).centers(:manager.not => user.staff_member).clients.loans.all.each{|loan|
      user.can_access?({:action => "show", :id => loan.id, :controller => "loans"}).should be_false
    }

    # admin & manage stuff: no access
    user.can_access?({:action => "index", :controller => "admin"}).should be_false
    user.can_access?({:action => "edit", :controller => "admin"}).should be_false

    user.can_access?({:action => "index", :controller => "holidays"}).should be_false
    user.can_access?({:action => "create", :controller => "holidays"}).should be_false
    user.can_access?({:action => "update", :controller => "holidays"}).should be_false

    user.can_access?({:action => "index", :controller => "regions"}).should be_false
    user.can_access?({:action => "create", :controller => "regions"}).should be_false
    user.can_access?({:action => "update", :controller => "regions"}).should be_false

    user.can_access?({:action => "index", :controller => "areas"}).should be_false
    user.can_access?({:action => "create", :controller => "areas"}).should be_false
    user.can_access?({:action => "update", :controller => "areas"}).should be_false

    user.can_access?({:action => "index", :controller => "staff_members"}).should be_true
    user.can_access?({:action => "create", :controller => "staff_members"}, {:staff_member => {:name => "foo"}}).should be_false
    user.can_access?({:action => "update", :controller => "staff_members"}).should be_false

    user.can_access?({:action => "index", :controller => "users"}).should be_false
    user.can_access?({:action => "update", :controller => "users"}).should be_false

    user.can_access?({:action => "index", :controller => "funders"}).should be_false
    user.can_access?({:action => "update", :controller => "funders"}).should be_false

    user.can_access?({:action => "index", :controller => "funding_lines", :funder_id => 1}).should be_false
    user.can_access?({:action => "update", :controller => "funding_lines", :funder_id => 1}).should be_false

    user.can_access?({:action => "index", :controller => "portfolios", :funder_id => 1}).should be_false
    user.can_access?({:action => "update", :controller => "portfolios", :funder_id => 1}).should be_false

    user.can_access?({:action => "index", :controller => "rules"}).should be_false
    user.can_access?({:action => "create", :controller => "rules"}).should be_false
    user.can_access?({:action => "update", :controller => "rules"}).should be_false

    user.can_access?({:action => "index", :controller => "targets"}).should be_false
    user.can_access?({:action => "create", :controller => "targets"}).should be_false
    user.can_access?({:action => "update", :controller => "targets"}).should be_false

    user.can_access?({:action => "index", :controller => "fees"}).should be_false
    user.can_access?({:action => "create", :controller => "fees"}).should be_false
    user.can_access?({:action => "update", :controller => "fees"}).should be_false

    user.can_access?({:action => "index", :controller => "loan_products"}).should be_false
    user.can_access?({:action => "create", :controller => "loan_products"}).should be_false
    user.can_access?({:action => "update", :controller => "loan_products"}).should be_false

    user.can_access?({:action => "index", :controller => "insurance_companies"}).should be_true
    user.can_access?({:action => "create", :controller => "insurance_companies"}).should be_true
    user.can_access?({:action => "update", :controller => "insurance_companies"}).should be_true

    user.can_access?({:action => "index", :controller => "accounts"}).should be_false
    user.can_access?({:action => "create", :controller => "accounts"}).should be_false
    user.can_access?({:action => "update", :controller => "accounts"}).should be_false

    user.can_access?({:action => "index", :controller => "client_types"}).should be_false
    user.can_access?({:action => "create", :controller => "client_types"}).should be_false
    user.can_access?({:action => "update", :controller => "client_types"}).should be_false

    user.can_access?({:action => "index", :controller => "occupations"}).should be_false
    user.can_access?({:action => "create", :controller => "occupations"}).should be_false
    user.can_access?({:action => "update", :controller => "occupations"}).should be_false

    user.can_access?({:action => "index", :controller => "loan_utilizations"}).should be_false
    user.can_access?({:action => "create", :controller => "loan_utilizations"}).should be_false
    user.can_access?({:action => "update", :controller => "loan_utilizations"}).should be_false

    user.can_access?({:action => "index", :controller => "document_types"}).should be_false
    user.can_access?({:action => "create", :controller => "document_types"}).should be_false
    user.can_access?({:action => "update", :controller => "document_types"}).should be_false

    user.can_access?({:action => "index", :controller => "audit_items"}).should be_true
    user.can_access?({:action => "create", :controller => "audit_items"}).should be_true
    user.can_access?({:action => "update", :controller => "audit_items"}).should be_true

    # upload, download stuff
    user.can_access?({:action => "upload", :controller => "admin"}).should be_false
    user.can_access?({:action => "download", :controller => "admin"}).should be_false
    user.can_access?({:action => "dirty_loans", :controller => "admin"}).should be_false
    user.can_access?({:action => "index", :controller => "dashboard"}).should be_true
    user.can_access?({:action => "index", :controller => "reports"}).should be_true

    user.can_access?({:action => "show", :controller => "audit_trails"}).should be_true
    user.can_access?({:action => "show", :controller => "audit_trails"}, {:audit_for => {:action => "show", :id => 1, :controller => "branches" }}).should be_true
    user.can_access?({:action => "show", :controller => "audit_trails"}, {:audit_for => {:action => "show", :id => 2, :controller => "branches" }}).should be_false
  end

  it "should give access to center manager as staff member for relevant stuff" do
    user = User.new(:login => "bm1",:created_at => "2002-11-23", :updated_at => "2003-11-23", :role => :staff_member)
    user.staff_member = Center.first.manager
    user.save

    #browse page links
    user.can_access?({:action =>"index", :controller =>"verifications"}).should be_false
    user.can_access?({:action =>"index", :controller =>"documents"}).should be_true
    user.can_access?({:action =>"index", :controller =>"accounts"}).should be_false
    user.can_access?({:action =>"index", :controller =>"browse"}).should be_true
    user.can_access?({:action =>"index", :namespace =>"data_entry", :controller => "index"}).should be_true
    user.can_access?({:action =>"hq_tab", :controller =>"browse"}).should be_true
    user.can_access?({:action => "index", :controller => "branches"}).should be_true

    #branch access
    user.staff_member.centers.branches.each{|branch|
      user.can_access?({:action => "show", :id => branch.id, :controller => "branches"}).should be_true
    }
    #branch creation
    user.can_access?({:action => "create", :controller => "branches"}, 
                     {:branch => {:name => "Bhopal 1", :address => "dzv fsb g", :contact_number => "90000000000", :manager_staff_id => 1, :code => "MPBPL01", :landmark => "New Bhopal", 
                         :creation_date => "27-11-2010", :area_id => 1}}).should be_false
    #center access
    user.staff_member.centers.each{|center|
      user.can_access?({:action => "show", :id => center.id, :controller => "centers", :branch_id => center.branch_id}).should be_true
    }
    #center creation...no access
    managed_centers = user.staff_member.centers
    user.can_access?({:action => "create", :controller => "centers", :branch_id => managed_centers.branches.first.id}, 
                     {:center => {
                         :name => "Center 1", :address => "dzv fsb g", :contact_number => "90000000000", :manager_staff_id => 1, :code => "MPBPL0101", :landmark => "New Bhopal", 
                         :creation_date => "27-11-2010", :meeting_time_hours => 8, :center_id => managed_centers.first.id, :meeting_day => "monday", :meeting_time_minutes => 30}
                     }).should be_false

    non_managed_centers = Center.all(:id.not => user.staff_member.centers.map{|x| x.id})
    user.can_access?({:action => "create", :controller => "centers"}, 
                     {:center => {:name => "Center 1", :address => "dzv fsb g", :contact_number => "90000000000", :manager_staff_id => 2, :code => "MPBPL0101", :landmark => "New Bhopal", 
                         :creation_date => "27-11-2010", :meeting_time_hours => 8, :branch_id => non_managed_centers.first.id, :meeting_day => "monday", 
                         :meeting_time_minutes => 30}}).should be_false

    #client access
    user.staff_member.branches.centers.clients.all.each{|client|
      user.can_access?({:action => "show", :id => client.id, :controller => "clients", :branch_id => client.center.branch_id, :center_id => client.center_id}).should be_true
    }
    #client creation
    user.can_access?({:action => "create", :controller => "clients"}, 
                      {:client => {
                         :center_id => managed_centers.first.id, :name => "piyush", :reference => "MPBPL0107012", :address => "", :date_of_birth => "03-03-1991", 
                         :client_type_id => 1}
                     }).should be_true
    user.can_access?({:action => "create", :controller => "clients"}, 
                      {:client => {
                         :center_id => non_managed_centers.first.id, :name => "piyush", :reference => "MPBPL0107012", :address => "", :date_of_birth => "03-03-1991", 
                         :client_type_id => 1}
                     }).should be_false
    #loan access
    user.staff_member.centers.clients.loans.all.each{|loan|
      user.can_access?({:action => "show", :id => loan.id, :controller => "loans"}).should be_true
    }
    #loans create
    user.can_access?({:action => "create", :controller => "loans"}, 
                      {:default_loan => {:loan_product_id => 1, :amount => 10000, :interest => 10, :applied_on => "03-03-2010", :scheduled_disbursement_date => "03-03-2010",
                          :scheduled_first_payment_date => "10-03-2010", :client_id => managed_centers.clients.first.id}, :loan_type => "DefaultLoan"}).should be_true
    # loan access should be denied for other branches
    user.can_access?({:action => "create", :controller => "loans"},
                      {:default_loan => {:loan_product_id => 1, :amount => 10000, :interest => 10, :applied_on => "03-03-2010", :scheduled_disbursement_date => "03-03-2010",
                          :scheduled_first_payment_date => "10-03-2010", :client_id => non_managed_centers.clients.first.id}, :loan_type => "DefaultLoan"}).should be_false
    #deny access
    #branch access
    Branch.all(:id.not => managed_centers.map{|x| x.branch_id}).each{|branch|
      user.can_access?({:action => "show", :id => branch.id, :controller => "branches"}).should be_false
    }
    #center access
    Center.all(:manager.not => user.staff_member).each{|center|
      user.can_access?({:action => "show", :id => center.id, :controller => "centers", :branch_id => center.branch_id}).should be_false
    }
    #client access
    Center.all(:manager.not => user.staff_member).clients.each{|client|
      user.can_access?({:action => "show", :id => client.id, :controller => "clients", :branch_id => client.center.branch_id, :center_id => client.center_id}).should be_false
    }
    #loan access
    Center.all(:manager.not => user.staff_member).clients.loans.all.each{|loan|
      user.can_access?({:action => "show", :id => loan.id, :controller => "loans"}).should be_false
    }

    # admin & manage stuff: no access
    user.can_access?({:action => "index", :controller => "admin"}).should be_false
    user.can_access?({:action => "edit", :controller => "admin"}).should be_false

    user.can_access?({:action => "index", :controller => "holidays"}).should be_false
    user.can_access?({:action => "create", :controller => "holidays"}).should be_false
    user.can_access?({:action => "update", :controller => "holidays"}).should be_false

    user.can_access?({:action => "index", :controller => "regions"}).should be_false
    user.can_access?({:action => "create", :controller => "regions"}).should be_false
    user.can_access?({:action => "update", :controller => "regions"}).should be_false

    user.can_access?({:action => "index", :controller => "areas"}).should be_false
    user.can_access?({:action => "create", :controller => "areas"}).should be_false
    user.can_access?({:action => "update", :controller => "areas"}).should be_false

    user.can_access?({:action => "index", :controller => "staff_members"}).should be_true
    user.can_access?({:action => "create", :controller => "staff_members"}).should be_false
    user.can_access?({:action => "update", :controller => "staff_members"}).should be_false

    user.can_access?({:action => "index", :controller => "users"}).should be_false
    user.can_access?({:action => "update", :controller => "users"}).should be_false

    user.can_access?({:action => "index", :controller => "funders"}).should be_false
    user.can_access?({:action => "update", :controller => "funders"}).should be_false

    user.can_access?({:action => "index", :controller => "funding_lines", :funder_id => 1}).should be_false
    user.can_access?({:action => "update", :controller => "funding_lines", :funder_id => 1}).should be_false

    user.can_access?({:action => "index", :controller => "portfolios", :funder_id => 1}).should be_false
    user.can_access?({:action => "update", :controller => "portfolios", :funder_id => 1}).should be_false

    user.can_access?({:action => "index", :controller => "rules"}).should be_false
    user.can_access?({:action => "create", :controller => "rules"}).should be_false
    user.can_access?({:action => "update", :controller => "rules"}).should be_false

    user.can_access?({:action => "index", :controller => "targets"}).should be_false
    user.can_access?({:action => "create", :controller => "targets"}).should be_false
    user.can_access?({:action => "update", :controller => "targets"}).should be_false

    user.can_access?({:action => "index", :controller => "fees"}).should be_false
    user.can_access?({:action => "create", :controller => "fees"}).should be_false
    user.can_access?({:action => "update", :controller => "fees"}).should be_false

    user.can_access?({:action => "index", :controller => "loan_products"}).should be_false
    user.can_access?({:action => "create", :controller => "loan_products"}).should be_false
    user.can_access?({:action => "update", :controller => "loan_products"}).should be_false

    user.can_access?({:action => "index", :controller => "insurance_companies"}).should be_true
    user.can_access?({:action => "create", :controller => "insurance_companies"}).should be_true
    user.can_access?({:action => "update", :controller => "insurance_companies"}).should be_true

    user.can_access?({:action => "index", :controller => "accounts"}).should be_false
    user.can_access?({:action => "create", :controller => "accounts"}).should be_false
    user.can_access?({:action => "update", :controller => "accounts"}).should be_false

    user.can_access?({:action => "index", :controller => "client_types"}).should be_false
    user.can_access?({:action => "create", :controller => "client_types"}).should be_false
    user.can_access?({:action => "update", :controller => "client_types"}).should be_false

    user.can_access?({:action => "index", :controller => "occupations"}).should be_false
    user.can_access?({:action => "create", :controller => "occupations"}).should be_false
    user.can_access?({:action => "update", :controller => "occupations"}).should be_false

    user.can_access?({:action => "index", :controller => "loan_utilizations"}).should be_false
    user.can_access?({:action => "create", :controller => "loan_utilizations"}).should be_false
    user.can_access?({:action => "update", :controller => "loan_utilizations"}).should be_false

    user.can_access?({:action => "index", :controller => "document_types"}).should be_false
    user.can_access?({:action => "create", :controller => "document_types"}).should be_false
    user.can_access?({:action => "update", :controller => "document_types"}).should be_false

    user.can_access?({:action => "index", :controller => "audit_items"}).should be_true
    user.can_access?({:action => "create", :controller => "audit_items"}).should be_true
    user.can_access?({:action => "update", :controller => "audit_items"}).should be_true

    # upload, download stuff
    user.can_access?({:action => "upload", :controller => "admin"}).should be_false
    user.can_access?({:action => "download", :controller => "admin"}).should be_false
    user.can_access?({:action => "dirty_loans", :controller => "admin"}).should be_false
    user.can_access?({:action => "index", :controller => "dashboard"}).should be_true
    user.can_access?({:action => "index", :controller => "reports"}).should be_true

    user.can_access?({:action => "show", :controller => "audit_trails"}).should be_true
    user.can_access?({:action => "show", :controller => "audit_trails"}, {:audit_for => {:action => "show", :id => managed_centers.branches.first.id, :controller => "branches" }}).should be_false
    user.can_access?({:action => "show", :controller => "audit_trails"}, {:audit_for => {:action => "show", :id => (Branch.all - managed_centers.branches).first.id, :controller => "branches" }}).should be_false

    user.can_access?({:action => "show", :controller => "audit_trails"}, {:audit_for => {:action => "show", :id => managed_centers.first.id, :controller => "branches" }}).should be_false
    user.can_access?({:action => "show", :controller => "audit_trails"}, {:audit_for => {:action => "show", :id => non_managed_centers.first.id, :controller => "branches" }}).should be_false
  end

  it "should give access to area manager as staff member for relevant stuff" do
    #area manager
    area = Area.first
    user = User.new(:login => "am1",:created_at => "2002-11-23", :updated_at => "2003-11-23", :role => :staff_member, :password => "password", :password_confirmation => "password",
                    :staff_member => area.manager)
    user.save_self.should be_true
    branch = Branch.first
    branch.area_id = area.id
    branch.save

    #browse page links
    user.can_access?({:action =>"index", :controller =>"verifications"}).should be_false
    user.can_access?({:action =>"index", :controller =>"documents"}).should be_true
    user.can_access?({:action =>"index", :controller =>"accounts"}).should be_false
    user.can_access?({:action =>"index", :controller =>"browse"}).should be_true
    user.can_access?({:action =>"index", :namespace =>"data_entry", :controller => "index"}).should be_true
    user.can_access?({:action =>"hq_tab", :controller =>"browse"}).should be_true
    user.can_access?({:action => "index", :controller => "branches"}).should be_true

    managed_branches = area.branches
    managed_centers  = area.branches.centers

    #branch access
    managed_branches.each{|branch|
      user.can_access?({:action => "show", :id => branch.id, :controller => "branches"}).should be_true
    }
    
    #branch creation
    user.can_access?({:action => "create", :controller => "branches"}, 
                     {:branch => {:name => "Bhopal 1", :address => "dzv fsb g", :contact_number => "90000000000", :manager_staff_id => 1, :code => "MPBPL01", :landmark => "New Bhopal", 
                         :creation_date => "27-11-2010", :area_id => area.id}}).should be_true
    #center access
    managed_centers.each{|center|
      user.can_access?({:action => "show", :id => center.id, :controller => "centers", :branch_id => center.branch_id}).should be_true
    }
    #center creation    
    user.can_access?({:action => "create", :controller => "centers", :branch_id => managed_branches.first.id}, 
                     {:center => {
                         :name => "Center 1", :address => "dzv fsb g", :contact_number => "90000000000", :manager_staff_id => 1, :code => "MPBPL0101", :landmark => "New Bhopal", 
                         :creation_date => "27-11-2010", :meeting_time_hours => 8, :branch_id => managed_branches.first.id, :meeting_day => "monday", :meeting_time_minutes => 30}
                     }).should be_true

    non_managed_centers  = Center.all(:id.not => managed_centers.map{|x| x.id})
    non_managed_branches = Branch.all(:id.not => managed_branches.map{|x| x.id})

    user.can_access?({:action => "create", :controller => "centers"}, 
                     {:center => {:name => "Center 1", :address => "dzv fsb g", :contact_number => "90000000000", :manager_staff_id => 2, :code => "MPBPL0101", :landmark => "New Bhopal", 
                         :creation_date => "27-11-2010", :meeting_time_hours => 8, :branch_id => non_managed_branches.first.id, :meeting_day => "monday", 
                         :meeting_time_minutes => 30}}).should be_false

    #client access
    managed_centers.clients.all.each{|client|
      user.can_access?({:action => "show", :id => client.id, :controller => "clients", :branch_id => client.center.branch_id, :center_id => client.center_id}).should be_true
    }
    #client creation
    user.can_access?({:action => "create", :controller => "clients"}, 
                      {:client => {
                         :center_id => managed_centers.first.id, :name => "piyush", :reference => "MPBPL0107012", :address => "", :date_of_birth => "03-03-1991", 
                         :client_type_id => 1}
                     }).should be_true
    user.can_access?({:action => "create", :controller => "clients"}, 
                      {:client => {
                         :center_id => non_managed_centers.first.id, :name => "piyush", :reference => "MPBPL0107012", :address => "", :date_of_birth => "03-03-1991", 
                         :client_type_id => 1}
                     }).should be_false
    #loan access
    user.staff_member.centers.clients.loans.all.each{|loan|
      user.can_access?({:action => "show", :id => loan.id, :controller => "loans"}).should be_true
    }
    #loans create
    user.can_access?({:action => "create", :controller => "loans"}, 
                      {:default_loan => {:loan_product_id => 1, :amount => 10000, :interest => 10, :applied_on => "03-03-2010", :scheduled_disbursement_date => "03-03-2010",
                          :scheduled_first_payment_date => "10-03-2010", :client_id => managed_centers.clients.first.id}, :loan_type => "DefaultLoan"}).should be_true
    # loan access should be denied for other branches
    user.can_access?({:action => "create", :controller => "loans"},
                      {:default_loan => {:loan_product_id => 1, :amount => 10000, :interest => 10, :applied_on => "03-03-2010", :scheduled_disbursement_date => "03-03-2010",
                          :scheduled_first_payment_date => "10-03-2010", :client_id => non_managed_centers.clients.first.id}, :loan_type => "DefaultLoan"}).should be_false
    #deny access
    #branch access
    Branch.all(:id.not => managed_centers.map{|x| x.branch_id}).each{|branch|
      user.can_access?({:action => "show", :id => branch.id, :controller => "branches"}).should be_false
    }
    #center access
    non_managed_centers.each{|center|
      user.can_access?({:action => "show", :id => center.id, :controller => "centers", :branch_id => center.branch_id}).should be_false
    }
    #client access
    non_managed_centers.clients.each{|client|
      user.can_access?({:action => "show", :id => client.id, :controller => "clients", :branch_id => client.center.branch_id, :center_id => client.center_id}).should be_false
    }
    #loan access
    non_managed_centers.clients.loans.all.each{|loan|
      user.can_access?({:action => "show", :id => loan.id, :controller => "loans"}).should be_false
    }

    # admin & manage stuff: no access
    user.can_access?({:action => "index", :controller => "admin"}).should be_false
    user.can_access?({:action => "edit", :controller => "admin"}).should be_false

    user.can_access?({:action => "index", :controller => "holidays"}).should be_false
    user.can_access?({:action => "create", :controller => "holidays"}).should be_false
    user.can_access?({:action => "update", :controller => "holidays"}).should be_false

    user.can_access?({:action => "index", :controller => "regions"}).should be_false
    user.can_access?({:action => "create", :controller => "regions"}).should be_false
    user.can_access?({:action => "update", :controller => "regions"}).should be_false

    user.can_access?({:action => "index", :controller => "areas"}).should be_true
    user.can_access?({:action => "create", :controller => "areas"}).should be_false
    user.can_access?({:action => "update", :controller => "areas"}).should be_false

    user.can_access?({:action => "index", :controller => "staff_members"}).should be_true
    user.can_access?({:action => "create", :controller => "staff_members"}).should be_true
    user.can_access?({:action => "update", :controller => "staff_members"}).should be_true

    user.can_access?({:action => "index", :controller => "users"}).should be_false
    user.can_access?({:action => "update", :controller => "users"}).should be_false

    user.can_access?({:action => "index", :controller => "funders"}).should be_false
    user.can_access?({:action => "update", :controller => "funders"}).should be_false

    user.can_access?({:action => "index", :controller => "funding_lines", :funder_id => 1}).should be_false
    user.can_access?({:action => "update", :controller => "funding_lines", :funder_id => 1}).should be_false

    user.can_access?({:action => "index", :controller => "portfolios", :funder_id => 1}).should be_false
    user.can_access?({:action => "update", :controller => "portfolios", :funder_id => 1}).should be_false

    user.can_access?({:action => "index", :controller => "rules"}).should be_false
    user.can_access?({:action => "create", :controller => "rules"}).should be_false
    user.can_access?({:action => "update", :controller => "rules"}).should be_false

    user.can_access?({:action => "index", :controller => "targets"}).should be_false
    user.can_access?({:action => "create", :controller => "targets"}).should be_false
    user.can_access?({:action => "update", :controller => "targets"}).should be_false

    user.can_access?({:action => "index", :controller => "fees"}).should be_false
    user.can_access?({:action => "create", :controller => "fees"}).should be_false
    user.can_access?({:action => "update", :controller => "fees"}).should be_false

    user.can_access?({:action => "index", :controller => "loan_products"}).should be_false
    user.can_access?({:action => "create", :controller => "loan_products"}).should be_false
    user.can_access?({:action => "update", :controller => "loan_products"}).should be_false

    user.can_access?({:action => "index", :controller => "insurance_companies"}).should be_true
    user.can_access?({:action => "create", :controller => "insurance_companies"}).should be_true
    user.can_access?({:action => "update", :controller => "insurance_companies"}).should be_true

    user.can_access?({:action => "index", :controller => "accounts"}).should be_false
    user.can_access?({:action => "create", :controller => "accounts"}).should be_false
    user.can_access?({:action => "update", :controller => "accounts"}).should be_false

    user.can_access?({:action => "index", :controller => "client_types"}).should be_false
    user.can_access?({:action => "create", :controller => "client_types"}).should be_false
    user.can_access?({:action => "update", :controller => "client_types"}).should be_false

    user.can_access?({:action => "index", :controller => "occupations"}).should be_false
    user.can_access?({:action => "create", :controller => "occupations"}).should be_false
    user.can_access?({:action => "update", :controller => "occupations"}).should be_false

    user.can_access?({:action => "index", :controller => "loan_utilizations"}).should be_false
    user.can_access?({:action => "create", :controller => "loan_utilizations"}).should be_false
    user.can_access?({:action => "update", :controller => "loan_utilizations"}).should be_false

    user.can_access?({:action => "index", :controller => "document_types"}).should be_false
    user.can_access?({:action => "create", :controller => "document_types"}).should be_false
    user.can_access?({:action => "update", :controller => "document_types"}).should be_false

    user.can_access?({:action => "index", :controller => "audit_items"}).should be_true
    user.can_access?({:action => "create", :controller => "audit_items"}).should be_true
    user.can_access?({:action => "update", :controller => "audit_items"}).should be_true

    # upload, download stuff
    user.can_access?({:action => "upload", :controller => "admin"}).should be_false
    user.can_access?({:action => "download", :controller => "admin"}).should be_false
    user.can_access?({:action => "dirty_loans", :controller => "admin"}).should be_false
    user.can_access?({:action => "index", :controller => "dashboard"}).should be_true
    user.can_access?({:action => "index", :controller => "reports"}).should be_true

    user.can_access?({:action => "show", :controller => "audit_trails"}).should be_true
    user.can_access?({:action => "show", :controller => "audit_trails"}, {:audit_for => {:action => "show", :id => managed_centers.branches.first.id, :controller => "branches" }}).should be_true
    user.can_access?({:action => "show", :controller => "audit_trails"}, {:audit_for => {:action => "show", :id => (Branch.all - managed_centers.branches).first.id, :controller => "branches" }}).should be_false

    user.can_access?({:action => "show", :controller => "audit_trails"}, {:audit_for => {:action => "show", :id => managed_centers.first.id, :controller => "branches" }}).should be_true
    user.can_access?({:action => "show", :controller => "audit_trails"}, {:audit_for => {:action => "show", :id => non_managed_centers.first.id, :controller => "branches" }}).should be_false
  end


  it "should give access to region manager as staff member for relevant stuff" do
    #area manager
    region = Region.first
    user = User.new(:login => "rm1",:created_at => "2002-11-23", :updated_at => "2003-11-23", :role => :staff_member, :password => "password", :password_confirmation => "password",
                    :staff_member => region.manager)
    user.save_self.should be_true
    branch = Branch.first
    branch.area_id = region.areas.first.id
    branch.save

    area =  region.areas.first

    #browse page links
    user.can_access?({:action =>"index", :controller =>"verifications"}).should be_false
    user.can_access?({:action =>"index", :controller =>"documents"}).should be_true
    user.can_access?({:action =>"index", :controller =>"accounts"}).should be_false
    user.can_access?({:action =>"index", :controller =>"browse"}).should be_true
    user.can_access?({:action =>"index", :namespace =>"data_entry", :controller => "index"}).should be_true
    user.can_access?({:action =>"hq_tab", :controller =>"browse"}).should be_true
    user.can_access?({:action => "index", :controller => "branches"}).should be_true

    managed_branches = region.areas.branches
    managed_centers  = region.areas.branches.centers

    #branch access
    managed_branches.each{|branch|
      user.can_access?({:action => "show", :id => branch.id, :controller => "branches"}).should be_true
    }
    
    #branch creation
    user.can_access?({:action => "create", :controller => "branches"}, 
                     {:branch => {:name => "Bhopal 1", :address => "dzv fsb g", :contact_number => "90000000000", :manager_staff_id => 1, :code => "MPBPL01", :landmark => "New Bhopal", 
                         :creation_date => "27-11-2010", :area_id => 1}}).should be_true
    #center access
    managed_centers.each{|center|
      user.can_access?({:action => "show", :id => center.id, :controller => "centers", :branch_id => center.branch_id}).should be_true
    }
    #center creation    
    user.can_access?({:action => "create", :controller => "centers", :branch_id => managed_branches.first.id}, 
                     {:center => {
                         :name => "Center 1", :address => "dzv fsb g", :contact_number => "90000000000", :manager_staff_id => 1, :code => "MPBPL0101", :landmark => "New Bhopal", 
                         :creation_date => "27-11-2010", :meeting_time_hours => 8, :branch_id => managed_branches.first.id, :meeting_day => "monday", :meeting_time_minutes => 30}
                     }).should be_true

    non_managed_centers  = Center.all(:id.not => managed_centers.map{|x| x.id})
    non_managed_branches = Branch.all(:id.not => managed_branches.map{|x| x.id})

    user.can_access?({:action => "create", :controller => "centers"}, 
                     {:center => {:name => "Center 1", :address => "dzv fsb g", :contact_number => "90000000000", :manager_staff_id => 2, :code => "MPBPL0101", :landmark => "New Bhopal", 
                         :creation_date => "27-11-2010", :meeting_time_hours => 8, :branch_id => non_managed_branches.first.id, :meeting_day => "monday", 
                         :meeting_time_minutes => 30}}).should be_false

    #client access
    managed_centers.clients.all.each{|client|
      user.can_access?({:action => "show", :id => client.id, :controller => "clients", :branch_id => client.center.branch_id, :center_id => client.center_id}).should be_true
    }
    #client creation
    user.can_access?({:action => "create", :controller => "clients"}, 
                      {:client => {
                         :center_id => managed_centers.first.id, :name => "piyush", :reference => "MPBPL0107012", :address => "", :date_of_birth => "03-03-1991", 
                         :client_type_id => 1}
                     }).should be_true
    user.can_access?({:action => "create", :controller => "clients"}, 
                      {:client => {
                         :center_id => non_managed_centers.first.id, :name => "piyush", :reference => "MPBPL0107012", :address => "", :date_of_birth => "03-03-1991", 
                         :client_type_id => 1}
                     }).should be_false
    #loan access
    user.staff_member.centers.clients.loans.all.each{|loan|
      user.can_access?({:action => "show", :id => loan.id, :controller => "loans"}).should be_true
    }
    #loans create
    user.can_access?({:action => "create", :controller => "loans"}, 
                      {:default_loan => {:loan_product_id => 1, :amount => 10000, :interest => 10, :applied_on => "03-03-2010", :scheduled_disbursement_date => "03-03-2010",
                          :scheduled_first_payment_date => "10-03-2010", :client_id => managed_centers.clients.first.id}, :loan_type => "DefaultLoan"}).should be_true
    # loan access should be denied for other branches
    user.can_access?({:action => "create", :controller => "loans"},
                      {:default_loan => {:loan_product_id => 1, :amount => 10000, :interest => 10, :applied_on => "03-03-2010", :scheduled_disbursement_date => "03-03-2010",
                          :scheduled_first_payment_date => "10-03-2010", :client_id => non_managed_centers.clients.first.id}, :loan_type => "DefaultLoan"}).should be_false
    #deny access
    #branch access
    Branch.all(:id.not => managed_centers.map{|x| x.branch_id}).each{|branch|
      user.can_access?({:action => "show", :id => branch.id, :controller => "branches"}).should be_false
    }
    #center access
    non_managed_centers.each{|center|
      user.can_access?({:action => "show", :id => center.id, :controller => "centers", :branch_id => center.branch_id}).should be_false
    }
    #client access
    non_managed_centers.clients.each{|client|
      user.can_access?({:action => "show", :id => client.id, :controller => "clients", :branch_id => client.center.branch_id, :center_id => client.center_id}).should be_false
    }
    #loan access
    non_managed_centers.clients.loans.all.each{|loan|
      user.can_access?({:action => "show", :id => loan.id, :controller => "loans"}).should be_false
    }

    # admin & manage stuff: no access
    user.can_access?({:action => "index", :controller => "admin"}).should be_false
    user.can_access?({:action => "edit", :controller => "admin"}).should be_false

    user.can_access?({:action => "index", :controller => "holidays"}).should be_false
    user.can_access?({:action => "create", :controller => "holidays"}).should be_false
    user.can_access?({:action => "update", :controller => "holidays"}).should be_false

    user.can_access?({:action => "index", :controller => "regions"}).should be_true
    user.can_access?({:action => "create", :controller => "regions"}).should be_false
    user.can_access?({:action => "update", :controller => "regions"}).should be_false

    user.can_access?({:action => "index", :controller => "areas"}).should be_true
    user.can_access?({:action => "create", :controller => "areas"}).should be_true
    user.can_access?({:action => "update", :controller => "areas"}).should be_true

    user.can_access?({:action => "index", :controller => "staff_members"}).should be_true
    user.can_access?({:action => "create", :controller => "staff_members"}).should be_true
    user.can_access?({:action => "update", :controller => "staff_members"}).should be_true

    user.can_access?({:action => "index", :controller => "users"}).should be_false
    user.can_access?({:action => "update", :controller => "users"}).should be_false

    user.can_access?({:action => "index", :controller => "funders"}).should be_false
    user.can_access?({:action => "update", :controller => "funders"}).should be_false

    user.can_access?({:action => "index", :controller => "funding_lines", :funder_id => 1}).should be_false
    user.can_access?({:action => "update", :controller => "funding_lines", :funder_id => 1}).should be_false

    user.can_access?({:action => "index", :controller => "portfolios", :funder_id => 1}).should be_false
    user.can_access?({:action => "update", :controller => "portfolios", :funder_id => 1}).should be_false

    user.can_access?({:action => "index", :controller => "rules"}).should be_false
    user.can_access?({:action => "create", :controller => "rules"}).should be_false
    user.can_access?({:action => "update", :controller => "rules"}).should be_false

    user.can_access?({:action => "index", :controller => "targets"}).should be_false
    user.can_access?({:action => "create", :controller => "targets"}).should be_false
    user.can_access?({:action => "update", :controller => "targets"}).should be_false

    user.can_access?({:action => "index", :controller => "fees"}).should be_false
    user.can_access?({:action => "create", :controller => "fees"}).should be_false
    user.can_access?({:action => "update", :controller => "fees"}).should be_false

    user.can_access?({:action => "index", :controller => "loan_products"}).should be_false
    user.can_access?({:action => "create", :controller => "loan_products"}).should be_false
    user.can_access?({:action => "update", :controller => "loan_products"}).should be_false

    user.can_access?({:action => "index", :controller => "insurance_companies"}).should be_true
    user.can_access?({:action => "create", :controller => "insurance_companies"}).should be_true
    user.can_access?({:action => "update", :controller => "insurance_companies"}).should be_true

    user.can_access?({:action => "index", :controller => "accounts"}).should be_false
    user.can_access?({:action => "create", :controller => "accounts"}).should be_false
    user.can_access?({:action => "update", :controller => "accounts"}).should be_false

    user.can_access?({:action => "index", :controller => "client_types"}).should be_false
    user.can_access?({:action => "create", :controller => "client_types"}).should be_false
    user.can_access?({:action => "update", :controller => "client_types"}).should be_false

    user.can_access?({:action => "index", :controller => "occupations"}).should be_false
    user.can_access?({:action => "create", :controller => "occupations"}).should be_false
    user.can_access?({:action => "update", :controller => "occupations"}).should be_false

    user.can_access?({:action => "index", :controller => "loan_utilizations"}).should be_false
    user.can_access?({:action => "create", :controller => "loan_utilizations"}).should be_false
    user.can_access?({:action => "update", :controller => "loan_utilizations"}).should be_false

    user.can_access?({:action => "index", :controller => "document_types"}).should be_false
    user.can_access?({:action => "create", :controller => "document_types"}).should be_false
    user.can_access?({:action => "update", :controller => "document_types"}).should be_false

    user.can_access?({:action => "index", :controller => "audit_items"}).should be_true
    user.can_access?({:action => "create", :controller => "audit_items"}).should be_true
    user.can_access?({:action => "update", :controller => "audit_items"}).should be_true

    # upload, download stuff
    user.can_access?({:action => "upload", :controller => "admin"}).should be_false
    user.can_access?({:action => "download", :controller => "admin"}).should be_false
    user.can_access?({:action => "dirty_loans", :controller => "admin"}).should be_false
    user.can_access?({:action => "index", :controller => "dashboard"}).should be_true
    user.can_access?({:action => "index", :controller => "reports"}).should be_true

    user.can_access?({:action => "show", :controller => "audit_trails"}).should be_true
    user.can_access?({:action => "show", :controller => "audit_trails"}, {:audit_for => {:action => "show", :id => managed_centers.branches.first.id, :controller => "branches" }}).should be_true
    user.can_access?({:action => "show", :controller => "audit_trails"}, {:audit_for => {:action => "show", :id => (Branch.all - managed_centers.branches).first.id, :controller => "branches" }}).should be_false

    user.can_access?({:action => "show", :controller => "audit_trails"}, {:audit_for => {:action => "show", :id => managed_centers.first.id, :controller => "branches" }}).should be_true
    user.can_access?({:action => "show", :controller => "audit_trails"}, {:audit_for => {:action => "show", :id => non_managed_centers.first.id, :controller => "branches" }}).should be_false
  end

  it "should give access to read only for relevant portions and should not allow any changes" do
    #area manager
    user = User.new(:login => "ro1",:created_at => "2002-11-23", :updated_at => "2003-11-23", :role => :read_only, :password => "password", :password_confirmation => "password")
                   
    user.save_self.should be_true
    #browse page links
    user.can_access?({:action =>"index", :controller =>"verifications"}).should be_false
    user.can_access?({:action =>"index", :controller =>"documents"}).should be_true
    user.can_access?({:action =>"index", :controller =>"accounts"}).should be_false
    user.can_access?({:action =>"index", :controller =>"browse"}).should be_true
    user.can_access?({:action => "index", :namespace =>"data_entry", :controller => "index"}).should be_false
    user.can_access?({:action =>"hq_tab", :controller =>"browse"}).should be_true
    user.can_access?({:action => "index", :controller => "branches"}).should be_true

    managed_branches = Branch.all
    managed_centers  = Center.all

    #branch access
    managed_branches.each{|branch|
      user.can_access?({:action => "show", :id => branch.id, :controller => "branches"}).should be_true
    }
    
    #branch creation
    user.can_access?({:action => "create", :controller => "branches"}, 
                     {:branch => {:name => "Bhopal 1", :address => "dzv fsb g", :contact_number => "90000000000", :manager_staff_id => 1, :code => "MPBPL01", :landmark => "New Bhopal", 
                         :creation_date => "27-11-2010", :area_id => 1}}).should be_false
    #center access
    managed_centers.each{|center|
      user.can_access?({:action => "show", :id => center.id, :controller => "centers", :branch_id => center.branch_id}).should be_true
    }
    #center creation    
    user.can_access?({:action => "create", :controller => "centers", :branch_id => managed_branches.first.id}, 
                     {:center => {
                         :name => "Center 1", :address => "dzv fsb g", :contact_number => "90000000000", :manager_staff_id => 1, :code => "MPBPL0101", :landmark => "New Bhopal", 
                         :creation_date => "27-11-2010", :meeting_time_hours => 8, :branch_id => managed_branches.first.id, :meeting_day => "monday", :meeting_time_minutes => 30}
                     }).should be_false

    #client access
    managed_centers.clients.all.each{|client|
      user.can_access?({:action => "show", :id => client.id, :controller => "clients", :branch_id => client.center.branch_id, :center_id => client.center_id}).should be_true
    }
    #client creation
    user.can_access?({:action => "create", :controller => "clients"}, 
                      {:client => {
                         :center_id => managed_centers.first.id, :name => "piyush", :reference => "MPBPL0107012", :address => "", :date_of_birth => "03-03-1991", 
                         :client_type_id => 1}
                     }).should be_false
    #loan access
    Loan.all.each{|loan|
      user.can_access?({:action => "show", :id => loan.id, :controller => "loans"}).should be_true
    }
    #loans create
    user.can_access?({:action => "create", :controller => "loans"}, 
                      {:default_loan => {:loan_product_id => 1, :amount => 10000, :interest => 10, :applied_on => "03-03-2010", :scheduled_disbursement_date => "03-03-2010",
                          :scheduled_first_payment_date => "10-03-2010", :client_id => managed_centers.clients.first.id}, :loan_type => "DefaultLoan"}).should be_false

    # admin & manage stuff: no access
    user.can_access?({:action => "index", :controller => "admin"}).should be_true
    user.can_access?({:action => "edit", :controller => "admin"}).should be_false

    user.can_access?({:action => "index", :controller => "holidays"}).should be_true
    user.can_access?({:action => "create", :controller => "holidays"}).should be_false
    user.can_access?({:action => "update", :controller => "holidays"}).should be_false

    user.can_access?({:action => "index", :controller => "regions"}).should be_true
    user.can_access?({:action => "create", :controller => "regions"}).should be_false
    user.can_access?({:action => "update", :controller => "regions"}).should be_false

    user.can_access?({:action => "index", :controller => "areas"}).should be_true
    user.can_access?({:action => "create", :controller => "areas"}).should be_false
    user.can_access?({:action => "update", :controller => "areas"}).should be_false

    user.can_access?({:action => "index", :controller => "staff_members"}).should be_true
    user.can_access?({:action => "create", :controller => "staff_members"}).should be_false
    user.can_access?({:action => "update", :controller => "staff_members"}).should be_false

    user.can_access?({:action => "index", :controller => "users"}).should be_false
    user.can_access?({:action => "update", :controller => "users"}).should be_false

    user.can_access?({:action => "index", :controller => "funders"}).should be_true
    user.can_access?({:action => "update", :controller => "funders"}).should be_false

    user.can_access?({:action => "index", :controller => "funding_lines", :funder_id => 1}).should be_false
    user.can_access?({:action => "update", :controller => "funding_lines", :funder_id => 1}).should be_false

    user.can_access?({:action => "index", :controller => "portfolios", :funder_id => 1}).should be_false
    user.can_access?({:action => "update", :controller => "portfolios", :funder_id => 1}).should be_false

    user.can_access?({:action => "index", :controller => "rules"}).should be_false
    user.can_access?({:action => "create", :controller => "rules"}).should be_false
    user.can_access?({:action => "update", :controller => "rules"}).should be_false

    user.can_access?({:action => "index", :controller => "targets"}).should be_false
    user.can_access?({:action => "create", :controller => "targets"}).should be_false
    user.can_access?({:action => "update", :controller => "targets"}).should be_false

    user.can_access?({:action => "index", :controller => "fees"}).should be_true
    user.can_access?({:action => "create", :controller => "fees"}).should be_false
    user.can_access?({:action => "update", :controller => "fees"}).should be_false

    user.can_access?({:action => "index", :controller => "loan_products"}).should be_true
    user.can_access?({:action => "create", :controller => "loan_products"}).should be_false
    user.can_access?({:action => "update", :controller => "loan_products"}).should be_false

    user.can_access?({:action => "index", :controller => "insurance_companies"}).should be_true
    user.can_access?({:action => "create", :controller => "insurance_companies"}).should be_false
    user.can_access?({:action => "update", :controller => "insurance_companies"}).should be_false

    user.can_access?({:action => "index", :controller => "accounts"}).should be_false
    user.can_access?({:action => "create", :controller => "accounts"}).should be_false
    user.can_access?({:action => "update", :controller => "accounts"}).should be_false

    user.can_access?({:action => "index", :controller => "client_types"}).should be_true
    user.can_access?({:action => "create", :controller => "client_types"}).should be_false
    user.can_access?({:action => "update", :controller => "client_types"}).should be_false

    user.can_access?({:action => "index", :controller => "occupations"}).should be_true
    user.can_access?({:action => "create", :controller => "occupations"}).should be_false
    user.can_access?({:action => "update", :controller => "occupations"}).should be_false

    user.can_access?({:action => "index", :controller => "loan_utilizations"}).should be_false
    user.can_access?({:action => "create", :controller => "loan_utilizations"}).should be_false
    user.can_access?({:action => "update", :controller => "loan_utilizations"}).should be_false

    user.can_access?({:action => "index", :controller => "document_types"}).should be_true
    user.can_access?({:action => "create", :controller => "document_types"}).should be_false
    user.can_access?({:action => "update", :controller => "document_types"}).should be_false

    user.can_access?({:action => "index", :controller => "audit_items"}).should be_false
    user.can_access?({:action => "create", :controller => "audit_items"}).should be_false
    user.can_access?({:action => "update", :controller => "audit_items"}).should be_false

    # upload, download stuff
    user.can_access?({:action => "upload", :controller => "admin"}).should be_false
    user.can_access?({:action => "download", :controller => "admin"}).should be_false
    user.can_access?({:action => "dirty_loans", :controller => "admin"}).should be_false
    user.can_access?({:action => "index", :controller => "dashboard"}).should be_true
    user.can_access?({:action => "index", :controller => "reports"}).should be_true

    user.can_access?({:action => "show", :controller => "audit_trails"}).should be_true
    user.can_access?({:action => "show", :controller => "audit_trails"}, {:audit_for => {:action => "show", :id => managed_centers.branches.first.id, :controller => "branches" }}).should be_true
  end

  it "should give access to data entry role for data entry screen only" do
    #area manager
    user = User.new(:login => "de1",:created_at => "2002-11-23", :updated_at => "2003-11-23", :role => :data_entry, :password => "password", :password_confirmation => "password")
    user.save_self.should be_true

    #browse page links
    user.can_access?({:action =>"index", :controller =>"verifications"}).should be_false
    user.can_access?({:action =>"index", :controller =>"documents"}).should be_true
    user.can_access?({:action =>"index", :controller =>"accounts"}).should be_false
    user.can_access?({:action =>"index", :controller =>"browse"}).should be_false
    user.can_access?({:action => "index", :namespace =>"data_entry", :controller => "index"}).should be_true
    user.can_access?({:action =>"hq_tab", :controller =>"browse"}).should be_false
    user.can_access?({:action => "index", :controller => "branches"}).should be_false
    user.can_access?({:action => "disbursement_sheet", :controller => "staff_members"}).should be_true
    user.can_access?({:action => "day_sheet", :controller => "staff_members"}).should be_true
    user.can_access?({:action => "show", :controller => "reports"}).should be_false
    user.can_access?({:action => "index", :controller => "reports"}).should be_false
    user.can_access?({:action => "show", :controller => "reports", :report_type => "DailyReport"}).should be_true
    user.can_access?({:action => "show", :controller => "reports", :report_type => "ProjectedReport"}).should be_true
    user.can_access?({:action => "show", :controller => "reports", :report_type => "TransactionLedger"}).should be_true
    user.can_access?({:action => "show", :controller => "reports", :report_type => "ConsolidatedReport"}).should be_false

    managed_branches = Branch.all
    managed_centers  = Center.all

    #branch access
    managed_branches.each{|branch|
      user.can_access?({:action => "show", :id => branch.id, :controller => "branches"}).should be_false
    }
    
    #branch creation
    user.can_access?({:action => "create", :controller => "branches"}, 
                     {:branch => {:name => "Bhopal 1", :address => "dzv fsb g", :contact_number => "90000000000", :manager_staff_id => 1, :code => "MPBPL01", :landmark => "New Bhopal", 
                         :creation_date => "27-11-2010", :area_id => 1}}).should be_false
    #center access
    managed_centers.each{|center|
      user.can_access?({:action => "show", :id => center.id, :controller => "centers", :branch_id => center.branch_id}).should be_false
    }
    #center creation    
    user.can_access?({:action => "create", :controller => "centers", :branch_id => managed_branches.first.id}, 
                     {:center => {
                         :name => "Center 1", :address => "dzv fsb g", :contact_number => "90000000000", :manager_staff_id => 1, :code => "MPBPL0101", :landmark => "New Bhopal", 
                         :creation_date => "27-11-2010", :meeting_time_hours => 8, :branch_id => managed_branches.first.id, :meeting_day => "monday", :meeting_time_minutes => 30}
                     }).should be_false

    #client access
    managed_centers.clients.all.each{|client|
      user.can_access?({:action => "show", :id => client.id, :controller => "clients", :branch_id => client.center.branch_id, :center_id => client.center_id}).should be_false
    }
    #client creation
    user.can_access?({:action => "create", :controller => "clients"}, 
                      {:client => {
                         :center_id => managed_centers.first.id, :name => "piyush", :reference => "MPBPL0107012", :address => "", :date_of_birth => "03-03-1991", 
                         :client_type_id => 1}
                     }).should be_true
    user.can_access?({:action => "update", :controller => "clients", :id => 1}, {}).should be_true

    #loan access
    Loan.all.each{|loan|
      user.can_access?({:action => "show", :id => loan.id, :controller => "loans"}).should be_false
    }
    #loans create
    user.can_access?({:action => "create", :controller => "loans"}, 
                      {:default_loan => {:loan_product_id => 1, :amount => 10000, :interest => 10, :applied_on => "03-03-2010", :scheduled_disbursement_date => "03-03-2010",
                          :scheduled_first_payment_date => "10-03-2010", :client_id => managed_centers.clients.first.id}, :loan_type => "DefaultLoan"}).should be_true
    user.can_access?({:action => "update", :controller => "loans", :id => 1}, {}).should be_true

    #client groups create
    user.can_access?({:action => "create", :controller => "client_groups"}, {:center_id => 1, :name => "foo", :code => "bar"}).should be_true
    user.can_access?({:action => "update", :controller => "client_groups", :id => 1}, {:center_id => 1, :name => "foo", :code => "bar"}).should be_true

    # admin & manage stuff: no access
    user.can_access?({:action => "index", :controller => "admin"}).should be_false
    user.can_access?({:action => "edit", :controller => "admin"}).should be_false

    user.can_access?({:action => "index", :controller => "holidays"}).should be_false
    user.can_access?({:action => "create", :controller => "holidays"}).should be_false
    user.can_access?({:action => "update", :controller => "holidays"}).should be_false

    user.can_access?({:action => "index", :controller => "regions"}).should be_false
    user.can_access?({:action => "create", :controller => "regions"}).should be_false
    user.can_access?({:action => "update", :controller => "regions"}).should be_false

    user.can_access?({:action => "index", :controller => "areas"}).should be_false
    user.can_access?({:action => "create", :controller => "areas"}).should be_false
    user.can_access?({:action => "update", :controller => "areas"}).should be_false

    user.can_access?({:action => "index", :controller => "staff_members"}).should be_false
    user.can_access?({:action => "create", :controller => "staff_members"}).should be_false
    user.can_access?({:action => "update", :controller => "staff_members"}).should be_false

    user.can_access?({:action => "index", :controller => "users"}).should be_false
    user.can_access?({:action => "update", :controller => "users"}).should be_false

    user.can_access?({:action => "index", :controller => "funders"}).should be_false
    user.can_access?({:action => "update", :controller => "funders"}).should be_false

    user.can_access?({:action => "index", :controller => "funding_lines", :funder_id => 1}).should be_false
    user.can_access?({:action => "update", :controller => "funding_lines", :funder_id => 1}).should be_false

    user.can_access?({:action => "index", :controller => "portfolios", :funder_id => 1}).should be_false
    user.can_access?({:action => "update", :controller => "portfolios", :funder_id => 1}).should be_false

    user.can_access?({:action => "index", :controller => "rules"}).should be_false
    user.can_access?({:action => "create", :controller => "rules"}).should be_false
    user.can_access?({:action => "update", :controller => "rules"}).should be_false

    user.can_access?({:action => "index", :controller => "targets"}).should be_false
    user.can_access?({:action => "create", :controller => "targets"}).should be_false
    user.can_access?({:action => "update", :controller => "targets"}).should be_false

    user.can_access?({:action => "index", :controller => "fees"}).should be_false
    user.can_access?({:action => "create", :controller => "fees"}).should be_false
    user.can_access?({:action => "update", :controller => "fees"}).should be_false

    user.can_access?({:action => "index", :controller => "loan_products"}).should be_false
    user.can_access?({:action => "create", :controller => "loan_products"}).should be_false
    user.can_access?({:action => "update", :controller => "loan_products"}).should be_false

    user.can_access?({:action => "index", :controller => "insurance_companies"}).should be_false
    user.can_access?({:action => "create", :controller => "insurance_companies"}).should be_false
    user.can_access?({:action => "update", :controller => "insurance_companies"}).should be_false

    user.can_access?({:action => "index", :controller => "accounts"}).should be_false
    user.can_access?({:action => "create", :controller => "accounts"}).should be_false
    user.can_access?({:action => "update", :controller => "accounts"}).should be_false

    user.can_access?({:action => "index", :controller => "client_types"}).should be_false
    user.can_access?({:action => "create", :controller => "client_types"}).should be_false
    user.can_access?({:action => "update", :controller => "client_types"}).should be_false

    user.can_access?({:action => "index", :controller => "occupations"}).should be_false
    user.can_access?({:action => "create", :controller => "occupations"}).should be_false
    user.can_access?({:action => "update", :controller => "occupations"}).should be_false

    user.can_access?({:action => "index", :controller => "loan_utilizations"}).should be_false
    user.can_access?({:action => "create", :controller => "loan_utilizations"}).should be_false
    user.can_access?({:action => "update", :controller => "loan_utilizations"}).should be_false

    user.can_access?({:action => "index", :controller => "document_types"}).should be_false
    user.can_access?({:action => "create", :controller => "document_types"}).should be_false
    user.can_access?({:action => "update", :controller => "document_types"}).should be_false

    user.can_access?({:action => "index", :controller => "audit_items"}).should be_false
    user.can_access?({:action => "create", :controller => "audit_items"}).should be_false
    user.can_access?({:action => "update", :controller => "audit_items"}).should be_false

    # upload, download stuff
    user.can_access?({:action => "upload", :controller => "admin"}).should be_false
    user.can_access?({:action => "download", :controller => "admin"}).should be_false
    user.can_access?({:action => "dirty_loans", :controller => "admin"}).should be_false
    user.can_access?({:action => "index", :controller => "dashboard"}).should be_false
    user.can_access?({:action => "index", :controller => "reports"}).should be_false

    user.can_access?({:action => "show", :controller => "audit_trails"}).should be_false
    user.can_access?({:action => "show", :controller => "audit_trails"}, {:audit_for => {:action => "show", :id => managed_centers.branches.first.id, :controller => "branches" }}).should be_false
  end
end

