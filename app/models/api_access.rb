require "rubygems"
require "httparty"

class ApiAccess
  include HTTParty
  base_uri 'http://localhost:4000/api/v1'
  basic_auth 'admin', 'password'
  format :xml   

  #user details
  def self.get_user_info
    get("/browse.xml")
  end 

  #get branches 
  def self.get_branches
    get("/branches.xml")
  end

  #get branch info
  def self.get_branch_info(id)
    get("/branches/#{id}.xml")
  end

  #get centers 
  def self.get_centers
    get("/centers.xml")
  end

  #get center info
  def self.get_center_info(id)
    get("/centers/#{id}.xml")
  end

  #get areas
  def self.get_areas
    get("/areas.xml")
  end

  #get area info
  def self.get_area_info(id)
    get("/areas/#{id}.xml")
  end

  #get staff_members
  def self.get_staff_members
    get("/staff_members.xml")
  end

  #get staff_member info
  def self.get_staff_member_info(id)
    get("/staff_members/#{id}.xml")
  end

  #get staff_member centers,banches,client, loans
  #option='centers' or option='clients' etc.
  def self.get_staff_member_info_full(id)
    get("/staff_members/#{id}.xml", :query => {:option =>"full"})
  end

end

