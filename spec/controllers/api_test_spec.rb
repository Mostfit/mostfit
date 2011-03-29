require "rexml/document"
require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')

API_URL = "http://localhost:4000/api/v1"

def get_response(url)
  req = Net::HTTP::Get.new(url.path)
  req.basic_auth 'admin', 'password'
  res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
  doc = REXML::Document.new res.body
  return doc
end
describe "Test the API call" do	
  it "Should be get login user info" do
    url = URI.parse("#{API_URL}/browse.xml")
    response = get_response(url)
    response.root.elements[1].get_text("login").should == "admin"
  end

  it "Should be get login user staff_member" do
    url = URI.parse("#{API_URL}/browse.xml")
    response = get_response(url)
    response.root.elements[1].elements["staff_member"].get_text("id").should_not == nil
  end

  it "Should be get all staff member" do
    url = URI.parse("#{API_URL}/staff_members.xml")
    response = get_response(url)
    response.root.elements[1].get_text("id").should_not == nil
  end

  it "Should be get staff member details" do
    #get staff member id logged user
    url = URI.parse("#{API_URL}/browse.xml")
    response = get_response(url)
    staff_member_id = response.root.elements[1].elements["staff_member"].get_text("id")

    url = URI.parse("#{API_URL}/staff_members/#{staff_member_id}.xml")
    response = get_response(url)
    response.root.elements[1].get_text("name").should_not == nil
  end

  it "Should be get staff member branches" do
    #get staff member id logged user
    url = URI.parse("#{API_URL}/browse.xml")
    response = get_response(url)
    staff_member_id = response.root.elements[1].elements["staff_member"].get_text("id")

    url = URI.parse("#{API_URL}/staff_members/4.xml?option=branches")
    req = Net::HTTP::Get.new(url.path)
    req.basic_auth 'admin', 'password'
    res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
    res.code.should ==  "200"
  end

  it "Should be get staff member centers" do
    url = URI.parse("#{API_URL}/browse.xml")
    response = get_response(url)
    staff_member_id = response.root.elements[1].elements["staff_member"].get_text("id")

    url = URI.parse("#{API_URL}/staff_members/4.xml?option=centers")
    req = Net::HTTP::Get.new(url.path)
    req.basic_auth 'admin', 'password'
    res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
    res.code.should ==  "200"
  end

  it "Should be get staff member clients" do
    url = URI.parse("#{API_URL}/browse.xml")
    response = get_response(url)
    staff_member_id = response.root.elements[1].elements["staff_member"].get_text("id")

    url = URI.parse("#{API_URL}/staff_members/4.xml?option=clients")
    req = Net::HTTP::Get.new(url.path)
    req.basic_auth 'admin', 'password'
    res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
    res.code.should ==  "200"
  end

  it "Should be get staff member loans" do
    url = URI.parse("#{API_URL}/browse.xml")
    response = get_response(url)
    staff_member_id = response.root.elements[1].elements["staff_member"].get_text("id")

    url = URI.parse("#{API_URL}/staff_members/4.xml?option=loans")
    req = Net::HTTP::Get.new(url.path)
    req.basic_auth 'admin', 'password'
    res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
    res.code.should ==  "200"
  end

  it "Should be get staff member areas" do
    url = URI.parse("#{API_URL}/browse.xml")
    response = get_response(url)
    staff_member_id = response.root.elements[1].elements["staff_member"].get_text("id")

    url = URI.parse("#{API_URL}/staff_members/4.xml?option=areas")
    req = Net::HTTP::Get.new(url.path)
    req.basic_auth 'admin', 'password'
    res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
    res.code.should ==  "200"
  end

  it "Should be get staff member regions" do
    url = URI.parse("#{API_URL}/browse.xml")
    response = get_response(url)
    staff_member_id = response.root.elements[1].elements["staff_member"].get_text("id")

    url = URI.parse("#{API_URL}/staff_members/4.xml?option=regions")
    req = Net::HTTP::Get.new(url.path)
    req.basic_auth 'admin', 'password'
    res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
    res.code.should ==  "200"
  end

  it "Should be get all branches" do
  end

  it "Should be get branch details" do
  end

  it "Should be get all centers" do
  end

  it "Should be get center details" do
  end

  it "Should be get all client groups" do
  end

  it "Should be get client group details" do
  end

  it "Should be get client loan details" do
  end
end
