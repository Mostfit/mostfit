require "rubygems"
require "httparty"

class ApiAccess
  include HTTParty
  base_uri 'http://localhost:4000/api/v1'
  format :xml   

  #user details
  def self.get_my_details(login, pwd)
    post("/users/my_details.xml",  :query => {:login => login, :password => pwd})
  end 

  #staff member info with their branches and center
  def self.get_staff_member_branches(login, pwd)
    get("/branches.xml",  :query => {:login => login, :password => pwd})
  end

  #staff member centers infromation 
  def self.get_staff_member_centers(id,login, pwd)
    get("/staff_members/#{id}/centers.xml",  :query => {:login => login, :password => pwd})
  end
  
  #staff member client infromation 
  def self.get_staff_member_clients(id,login, pwd)
    get("/staff_members/#{id}/clients.xml",  :query => {:login => login, :password => pwd})
  end

  #staff member loans infromation 
  def self.get_staff_member_loans(id,login, pwd)
    get("/staff_members/#{id}/loans.xml",  :query => {:login => login, :password => pwd})
  end

  #staff member day sheet infromation 
  def self.get_staff_member_day_sheet(id,login, pwd)
    get("/staff_members/#{id}/day_sheet.xml",  :query => {:login => login, :password => pwd})
  end

  #Get payment details by center
  def self.get_staff_payments_by_center(center_id,login, pwd)
    get("/data_entry/payments/by_center.xml",  :query => {:center_id =>center_id, :login => login, :password => pwd})
  end
  
  #Create payment by client at center on date accepted by staff member
  def self.create_client_payments(center_id,login, pwd)
    post("/data_entry/payments/by_center.xml",  :query => {:center_id =>center_id, :login => login, :password => pwd, :received_on =>"2011-03-22", :paid =>{:loan =>{"532"=>"10.0"}}, :payment_style =>{"532"=>"prorata"}, :attendance =>{"520"=>"present"}, :payment =>{"received_by"=>"5"}})
  end

  #Get Regions details
  def self.get_regions(login, pwd)
    get("/regions.xml",  :query => {:login => login, :password => pwd})
  end

  #Get areas details
  def self.get_areas(login, pwd)
    get("/areas.xml",  :query => {:login => login, :password => pwd})
  end

  #Get client groups details
  def self.get_client_groups(login, pwd)
    get("/client_groups.xml",  :query => {:login => login, :password => pwd})
  end

  #Get centers paying today 
  def self.get_centers_paying_today(login, pwd)
    get("/browse/centers_paying_today.xml",  :query => {:login => login, :password => pwd})
  end

  #Fetch clients for center 
  def self.get_clients_for_center(id,login, pwd)
    get("/centers/#{id}.xml",  :query => {:login => login, :password => pwd})
  end

  #Fetch loans for client
  def self.get_loans_for_client(branch_id, center_id, client_id, login, pwd)
    get("/branches/#{branch_id}/centers/#{center_id}/clients/#{client_id}.xml",  :query => {:login => login, :password => pwd})
  end
end

