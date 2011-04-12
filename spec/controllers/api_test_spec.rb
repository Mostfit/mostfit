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
      url = URI.parse("#{API_URL}/staff_members/#{staff_member_id}.xml?option=branches")
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
    staff_meb_present = doc.root.elements[1].elements["staff_member"]

    if not staff_meb_present.blank? 
      staff_meb_present =  doc.root.elements[1].elements["staff_member"].get_text("id")
      url = URI.parse("#{API_URL}/staff_members/#{staff_member_id}.xml?option=centers")
      res = get_response(url)
      doc = REXML::Document.new res.body
      doc.root.elements[1].should_not == nil
      res.code.should ==  "200"
    end
  end

  it "Should be get staff member clients" do
    url = URI.parse("#{API_URL}/browse.xml")
    res = get_response(url)
    doc = REXML::Document.new res.body
    staff_meb_present = doc.root.elements[1].elements["staff_member"]

    if not staff_meb_present.blank? 
      staff_meb_present =  doc.root.elements[1].elements["staff_member"].get_text("id")
      url = URI.parse("#{API_URL}/staff_members/#{staff_member_id}.xml?option=clients")
      res = get_response(url)
      doc = REXML::Document.new res.body
      doc.root.elements[1].should_not == nil
      res.code.should ==  "200"
    end
  end

  it "Should be get staff member loans" do
    url = URI.parse("#{API_URL}/browse.xml")
    res = get_response(url)
    doc = REXML::Document.new res.body
    staff_meb_present = doc.root.elements[1].elements["staff_member"]

    if not staff_meb_present.blank? 
      staff_meb_present =  doc.root.elements[1].elements["staff_member"].get_text("id")
      url = URI.parse("#{API_URL}/staff_members/#{staff_member_id}.xml?option=loans")
      res = get_response(url)
      doc = REXML::Document.new res.body
      doc.root.elements[1].should_not == nil
      res.code.should ==  "200"
    end
  end

  it "Should be get staff member areas" do
    url = URI.parse("#{API_URL}/browse.xml")
    res = get_response(url)
    doc = REXML::Document.new res.body
    staff_meb_present = doc.root.elements[1].elements["staff_member"]

    if not staff_meb_present.blank? 
      staff_meb_present =  doc.root.elements[1].elements["staff_member"].get_text("id")
      url = URI.parse("#{API_URL}/staff_members/#{staff_member_id}.xml?option=areas")
      res = get_response(url)
      doc = REXML::Document.new res.body
      doc.root.elements[1].should_not == nil
      res.code.should ==  "200"
    end
  end

  it "Should be get staff member regions" do
    url = URI.parse("#{API_URL}/browse.xml")
    res = get_response(url)
    doc = REXML::Document.new res.body
    staff_meb_present = doc.root.elements[1].elements["staff_member"]

    if not staff_meb_present.blank? 
      staff_meb_present =  doc.root.elements[1].elements["staff_member"].get_text("id")
      url = URI.parse("#{API_URL}/staff_members/#{staff_member_id}.xml?option=regions")
      res = get_response(url)
      doc = REXML::Document.new res.body
      doc.root.elements[1].should_not == nil
      res.code.should ==  "200"
    end
  end

  it "Should be get all branches" do
    url = URI.parse("#{API_URL}/branches.xml")
    res = get_response(url)
    doc = REXML::Document.new res.body
    doc.root.elements[1].should_not == nil
    res.code.should ==  "200"
  end

  it "Should be get branch details" do
    url = URI.parse("#{API_URL}/branches.xml")
    res = get_response(url)
    doc = REXML::Document.new res.body
    get_branch = doc.root.elements[1].elements["branch"]
    if not get_branch.blank? 
      branch_id =  doc.root.elements[1].elements["branch"].get_text("id")
      url = URI.parse("#{API_URL}/branches/#{branch_id}.xml")
      res = get_response(url)
      doc = REXML::Document.new res.body
      doc.root.elements[1].should_not == nil
      res.code.should ==  "200"
    end
  end

  it "Should be get all centers" do
    url = URI.parse("#{API_URL}/centers.xml")
    res = get_response(url)
    doc = REXML::Document.new res.body
    doc.root.elements[1].should_not == nil
    res.code.should ==  "200"
  end

  it "Should be get center details" do
    url = URI.parse("#{API_URL}/centers.xml")
    res = get_response(url)
    doc = REXML::Document.new res.body
    get_center = doc.root.elements[1].elements["center"]
    if not get_center.blank? 
      center_id =  doc.root.elements[1].elements["center"].get_text("id")
      url = URI.parse("#{API_URL}/centers/#{center_id}.xml")
      res = get_response(url)
      doc = REXML::Document.new res.body
      doc.root.elements[1].should_not == nil
      res.code.should ==  "200"
    end
  end

  it "Should be get all client groups" do
    url = URI.parse("#{API_URL}/client_groups.xml")
    res = get_response(url)
    doc = REXML::Document.new res.body
    doc.root.elements[1].should_not == nil
    res.code.should ==  "200"
  end

  it "Should be get client group details" do
    url = URI.parse("#{API_URL}/client_groups.xml")
    res = get_response(url)
    doc = REXML::Document.new res.body
    get_client_group = doc.root.elements[1].elements["client_group"]
    if not get_client_group.blank? 
      client_group_id =  doc.root.elements[1].elements["client_group"].get_text("id")
      url = URI.parse("#{API_URL}/client_groups/#{client_group_id}.xml")
      res = get_response(url)
      doc = REXML::Document.new res.body
      doc.root.elements[1].should_not == nil
      res.code.should ==  "200"
    end
  end

  it "Should be get all loan_products" do
    url = URI.parse("#{API_URL}/loan_products.xml")
    res = get_response(url)
    doc = REXML::Document.new res.body
    doc.root.elements[1].should_not == nil
    res.code.should ==  "200"
  end

  it "Should be get loan_product details" do
    url = URI.parse("#{API_URL}/loan_products.xml")
    res = get_response(url)
    doc = REXML::Document.new res.body
    get_loan_product = doc.root.elements[1].elements["loan_product"]
    if not get_loan_product.blank? 
      loan_product_id =  doc.root.elements[1].elements["loan_product"].get_text("id")
      url = URI.parse("#{API_URL}/loan_products/#{loan_product_id}.xml")
      res = get_response(url)
      doc = REXML::Document.new res.body
      doc.root.elements[1].should_not == nil
      res.code.should ==  "200"
    end
  end
  
  it "Should be create client_group" do
  end

end
