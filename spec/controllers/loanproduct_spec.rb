require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')

describe LoanProducts, "Check loan product" do
  before do
    load_fixtures :users, :staff_members, :regions, :areas, :branches, :centers, :client_types, :clients, :loan_products
  end

  it "create a new loan_product" do
    
    response = request url(:perform_login), :method => "PUT", :params => {:login => 'admin', :password => 'password'}
    response.should redirect
    request(resource(:loan_products)).should be_successful
    params = {}
    params[:loan_product] =
      {
      :name => "Gold Plus",:min_amount => "1000", :max_amount => "15000",:amount_multiple => "100",:min_interest_rate => "12.5",
      :max_interest_rate =>    "18.0", :interest_rate_multiple => "1", :min_number_of_installments => "40", :max_number_of_installments => "60",  
      :installment_frequency => "weekly",  :loan_type => "DefaultLoan",:valid_from => {"month"=>"1", "day"=>"1", "year"=>"2010"},
      :valid_upto => {"month"=>"1", "day"=>"1", "year"=>"2012"}
      }
    response = request resource(:loan_products), :method => "POST", :params => params
    response.should redirect
    LoanProduct.first(:name => "Gold Plus").should_not nil
  end

  it "edit a new loan_product" do
    response = request url(:perform_login), :method => "PUT", :params => {:login => 'admin', :password => 'password'}
    response.should redirect
    @loan_product =  LoanProduct.first
    request(resource(@loan_product)).should be_successful
    params = {}
    hash = @loan_product.attributes
 #  hash.delete(:created_at)
    hash[:name]             = hash[:name]+"_modified"
    params[:id]             = @loan_product.id
    params[:loan_product]   = hash
    response = request resource(@loan_product), :method => "POST", :params => params
#    response.should redirect
    new_name = LoanProduct.get(@loan_product.id).name
    new_name.should_not equal(@loan_product.name)
  end

end
