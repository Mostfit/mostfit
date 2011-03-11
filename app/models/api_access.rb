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
    post("/staff_member/branches.xml",  :query => {:id => id, :login => login, :password => pwd})
  end

  #staff member day sheet infromation 
  def self.get_staff_member_day_sheet(id, date, login, pwd)
    post("/staff_member/day_sheet.xml",  :query => {:id => id, :date => date, :login => login, :password => pwd})
  end
end

