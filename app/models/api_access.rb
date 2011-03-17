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
  def self.get_staff_member_branches(id, login, pwd)
    get("/staff_member/#{id}/branches.xml",  :query => {:login => login, :password => pwd})
  end

  #staff member centers infromation 
  def self.get_staff_member_centers(id,login, pwd)
    get("/staff_member/#{id}/centers.xml",  :query => {:login => login, :password => pwd})
  end
  
  #staff member client infromation 
  def self.get_staff_member_clients(id,login, pwd)
    get("/staff_member/#{id}/clients.xml",  :query => {:login => login, :password => pwd})
  end

  #staff member loans infromation 
  def self.get_staff_member_loans(id,login, pwd)
    get("/staff_member/#{id}/loans.xml",  :query => {:login => login, :password => pwd})
  end

  #staff member day sheet infromation 
  def self.get_staff_member_day_sheet(id,login, pwd)
    get("/staff_member/#{id}/day_sheet.xml",  :query => {:login => login, :password => pwd})
  end

  #Get payment details by center
  def self.get_staff_payments_by_center(center_id,login, pwd)
    get("/data_entry/payments/by_center.xml",  :query => {:center_id =>center_id, :login => login, :password => pwd})
  end
end

