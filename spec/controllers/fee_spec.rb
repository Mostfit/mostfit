require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')

describe Fees, "Check fees" do
  before do
    load_fixtures :users, :staff_members, :regions, :areas, :branches, :centers, :client_groups, :client_types,:fees

  end 

 it "create a new fee" do
    response = request url(:perform_login), :method => "PUT", :params => {:login => 'admin', :password => 'password'}
    response.should redirect
    request("/fees/new").should be_successful
    params = {}
    params[:fee] = {:name => "Gold", :percentage => "12", :amount => "300", :min_amount => "100", :max_amount => "300", :payable_on => "loan_applied_on" }
    response = request resource(:fees), :method => "POST", :params => params
    response.should redirect
    Fee.first(:name => "Gold").should_not nil
  end


  it "edit a fees" do
    response = request url(:perform_login), :method => "PUT",:params  => {:login => 'admin', :password => 'password'}
    response.should redirect
    @fee= Fee.first 
    request(resource(@fee)).should be_successful
    params = {}
    hash = @fee.attributes
    hash[:name] = @fee.name+"_modified"
    params[:id] = @fee.id
    response = request resource(@fee), :method => "POST", :params => params
    new_fee = Fee.get(@fee.id).name  
    new_fee.should_not be_equal(@fee.name)
  end
end
