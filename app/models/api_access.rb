require "rubygems"
require "httparty"

class ApiAccess
  include HTTParty
  base_uri 'http://localhost:4000/api/v1'
  format :xml   
  def self.get_my_details(login, pwd)
    post("/users/my_details.xml",  :query => {:login => login, :password => pwd})
  end 
  
  def self.get_staff_members(id, login, pwd)
    post("/staff_members/show.xml",  :query => {:id => id, :login => login, :password => pwd})
  end
  
  def self.get_staff_member_day_sheet(id, date, login, pwd)
    post("/staff_members/day_sheet.xml",  :query => {:id => id, :date => date, :login => login, :password => pwd})
  end
end

