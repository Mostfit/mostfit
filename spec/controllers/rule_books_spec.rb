require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')
Merb.start_environment(:environment => ENV['MERV_ENV'] || 'development')

describe RuleBooks, "Check rules" do
  before do
    load_fixtures :users, :staff_members, :account, :branches
  end

  it "create a new rule" do

    response = request url(:perform_login), :method => "PUT", :params => {:login => 'admin', :password => 'password'}
    response.should redirect
    request("/rule_books").should be_successful
    @branch           = Branch.first
    @staff_member     = StaffMember.first
    params = {}
    @credit_account   = Account.first
    @debit_account    = Account.last
    
    params[:rule_book] = 
      {"name"=>"Rule1", "branch_id"=> @branch.id, "action"=>"principal", 
      "credit_accounts" => {
        "1"=>{"account_id"=> @credit_account.id, "percentage"=>"100"}, 
        "2"=>{"account_id"=>"", "percentage"=>"0"}, 
        "3"=>{"account_id"=>"", "percentage"=>"0"}
      }, 
      "debit_accounts"=>{
        "1"=>{"account_id"=> @debit_account.id, "percentage"=>"100"}, 
        "2"=>{"account_id"=>"", "percentage"=>"0"}, 
        "3"=>{"account_id"=>"", "percentage"=>"0"}
      }
    }
    response = request resource(:rule_books), :method => "POST", :params => params
    response.should redirect
    RuleBook.first(:name => "Rule1").should_not nil
 end

  it "edit a new rule" do
    response = request url(:perform_login), :method => "PUT", :params => {:login => 'admin', :password => 'password'}
    
    response.should redirect
   
    @rule_book = RuleBook.first
        
    request(resource(:rule_books)).should be_successful
    
    params = {}
   
    hash                 = @rule_book.attributes
    hash[:name]          = @rule_book.name + "_modified"
    params[:id]          = @rule_book.id
    params[:rule_book]   = hash
    
    response = request resource(:rule_books), :method => "POST", :params => params
    
  #  response.should redirect

    new_name = RuleBook.get(@rule_book.id).name
    new_name.should_not equal(@rule_book.name)
  end
end

    
