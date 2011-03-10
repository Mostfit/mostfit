require "rubygems"
require "httparty"

class ApiAccess
  include HTTParty
  base_uri 'http://localhost:4000/api/v1'
  format :xml   
  def self.get_user_info(login, pwd)
    put("/login.xml",  :query => {:login => login, :password => pwd})
  end 
end

