require "rubygems"
require "httparty"
require "base64"

# If require response work like hash uncomment this line
# eg: res.a.parsed_response.xml.user.login
#class Hash
# def method_missing(key)
#  self[key.to_s] || super
#end
#end

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

  #get loan_product
  def self.get_loan_products
    get("/loan_products.xml")
  end

  #get loan_product info
  def self.get_loan_product_info(id)
    get("/loan_products/#{id}.xml")
  end

  #get staff_member centers,banches,client, loans
  #option='centers' or option='clients' etc.
  def self.get_staff_member_info_full(id)
    get("/staff_members/#{id}.xml", :query => {:option =>"full"})
  end

  #branch: 1, center : 8, client :119
  def self.update_fingerprint(branch,center,client)
    image = Base64.encode64("#{File.read('/home/kiran/Desktop/sample.fpt')}") 
    put("/branches/#{branch}/centers/#{center}/clients/#{client}.xml", :query => {:client => {:fingerprint => image}})
  end
  
   def self.create_client(branch,center)
    post("/branches/#{branch}/centers/#{center}/clients.xml", :query => {:client => {:name => "my new client", :reference => "BS0999", :date_joined => "2011-04-05", :client_type_id => 1}})
  end
end

