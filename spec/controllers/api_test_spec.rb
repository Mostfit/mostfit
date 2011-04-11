require "rexml/document"
require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')

API_URL = "http://localhost:4000/api/v1"

def get_response(url)
  req = Net::HTTP::Get.new(url.path)
  req.basic_auth 'admin', 'password'
  res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
  return res
end
describe "Test the API call" do	
  it "Should be get login user info" do
    url = URI.parse("#{API_URL}/browse.xml")
    res = get_response(url)
    doc = REXML::Document.new res.body
    doc.root.elements[1].get_text("login").should == "admin"
  end

  it "Should be get login user staff_member" do
    url = URI.parse("#{API_URL}/browse.xml")
    res = get_response(url)
    doc = REXML::Document.new res.body
    doc.root.elements[1].should_not == nil
    res.code.should ==  "200"
  end

  it "Should be get all staff member" do
    url = URI.parse("#{API_URL}/staff_members.xml")
    res = get_response(url)
    doc = REXML::Document.new res.body
    doc.root.elements[1].should_not == nil
    res.code.should ==  "200"
  end

  it "Should be get staff member details" do
    #get staff member id logged user
    url = URI.parse("#{API_URL}/browse.xml")
    res = get_response(url)
    doc = REXML::Document.new res.body
    staff_meb_present =  doc.root.elements[1].elements["staff_member"]

    if not staff_meb_present.blank? 
      staff_meb_present =  doc.root.elements[1].elements["staff_member"].get_text("id")
      url = URI.parse("#{API_URL}/staff_members/#{staff_member_id}.xml")
      res = get_response(url)
      doc = REXML::Document.new res.body
      doc.root.elements[1].should_not == nil
      res.code.should ==  "200"
    end
  end

  it "Should be get staff member branches" do
    #get staff member id logged user
    url = URI.parse("#{API_URL}/browse.xml")
    res = get_response(url)
    doc = REXML::Document.new res.body
    staff_meb_present = doc.root.elements[1].elements["staff_member"]

    if not staff_meb_present.blank? 
      staff_meb_present =  doc.root.elements[1].elements["staff_member"].get_text("id")
      url = URI.parse("#{API_URL}/staff_members/#{staff_member_id}.xml")
      res = get_response(url)
      doc = REXML::Document.new res.body
      doc.root.elements[1].should_not == nil
      res.code.should ==  "200"
    end
  end

  it "Should be get staff member centers" do
    url = URI.parse("#{API_URL}/browse.xml")
    res = get_response(url)
    doc = REXML::Document.new res.body
    staff_member_id = doc.root.elements[1].elements["staff_member"].get_text("id")

    url = URI.parse("#{API_URL}/staff_members/#{staff_member_id}.xml?option=centers")
    req = Net::HTTP::Get.new(url.path)
    req.basic_auth 'admin', 'password'
    res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
    res.code.should ==  "200"
  end

  it "Should be get staff member clients" do
    url = URI.parse("#{API_URL}/browse.xml")
    res = get_response(url)
    doc = REXML::Document.new res.body
    staff_member_id = doc.root.elements[1].elements["staff_member"].get_text("id")

    url = URI.parse("#{API_URL}/staff_members/#{staff_member_id}.xml?option=clients")
    req = Net::HTTP::Get.new(url.path)
    req.basic_auth 'admin', 'password'
    res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
    res.code.should ==  "200"
  end

  it "Should be get staff member loans" do
    url = URI.parse("#{API_URL}/browse.xml")
    res = get_response(url)
    doc = REXML::Document.new res.body
    staff_member_id = doc.root.elements[1].elements["staff_member"].get_text("id")

    url = URI.parse("#{API_URL}/staff_members/#{staff_member_id}.xml?option=loans")
    req = Net::HTTP::Get.new(url.path)
    req.basic_auth 'admin', 'password'
    res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
    res.code.should ==  "200"
  end

  it "Should be get staff member areas" do
    url = URI.parse("#{API_URL}/browse.xml")
    res = get_response(url)
    doc = REXML::Document.new res.body
    staff_member_id = doc.root.elements[1].elements["staff_member"].get_text("id")

    url = URI.parse("#{API_URL}/staff_members/#{staff_member_id}.xml?option=areas")
    req = Net::HTTP::Get.new(url.path)
    req.basic_auth 'admin', 'password'
    res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
    res.code.should ==  "200"
  end

  it "Should be get staff member regions" do
    url = URI.parse("#{API_URL}/browse.xml")
    res = get_response(url)
    doc = REXML::Document.new res.body
    staff_member_id = doc.root.elements[1].elements["staff_member"].get_text("id")

    url = URI.parse("#{API_URL}/staff_members/#{staff_member_id}.xml?option=regions")
    req = Net::HTTP::Get.new(url.path)
    req.basic_auth 'admin', 'password'
    res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
    res.code.should ==  "200"
  end

  it "Should be get all branches" do
    url = URI.parse("#{API_URL}/branches.xml")
    res = get_response(url)
    doc = REXML::Document.new res.body
    doc.root.elements[1].should_not == nil
    res.code.should ==  "200"
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
