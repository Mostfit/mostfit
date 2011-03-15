require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')

describe StaffMembers, "API call" do
  before(:all) do
    load_fixtures :users, :staff_members, :branches, :centers 
    @u_admin = User.new(:login => 'staff_member', :password => 'staff_member', :password_confirmation => 'staff_member', :role => :staff_member)
    @u_admin.save
  end

  it "Should be get staff member branches" do
   params = {}
    params = {:format =>"xml", :login=>"staff_member", :password=>"staff_member"}
    response = post("/api/v1/staff_member/1/branches.xml", params)
    response.body.to_s.should  =~ /<name>Fatima<\/name>/
    #branch id =1 and branch name = Mumbai
    response.body.to_s.should  =~ /<id>1<\/id>/
    response.body.to_s.should  =~ /<name>Mumbai<\/name>/
  end
  
  it "Should be get staff member centers" do
    params = {}
    params = {:format =>"xml", :login=>"staff_member", :password=>"staff_member"}
    response = post("/api/v1/staff_member/4/centers.xml", params)
    response.body.to_s.should  =~ /<name>Fatima<\/name>/
    response.body.to_s.should  =~ /<name>JQZII001<\/name>/
  end
  
  it "Should be get staff member clients" do
    params = {}
    params = {:format =>"xml", :login=>"staff_member", :password=>"staff_member"}
    response = post("/api/v1/staff_member/4/clients.xml", params)
    response.body.to_s.should  =~ /<name>Fatima<\/name>/
   #TODO check responce with client data
  end
  
  it "Should be get staff member loans" do
    params = {}
    params = {:format =>"xml", :login=>"staff_member", :password=>"staff_member"}
    response = post("/api/v1/staff_member/4/loans.xml", params)
    response.body.to_s.should  =~ /<name>Fatima<\/name>/
   #TODO check responce with loans data 
  end
end
