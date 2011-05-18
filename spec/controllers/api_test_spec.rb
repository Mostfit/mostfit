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

  it "Should be get all holidays" do
    url = URI.parse("#{API_URL}/holidays.xml")
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
  
  it "Should be get center weeksheet" do
    url = URI.parse("#{API_URL}/centers.xml")
    res = get_response(url)
    doc = REXML::Document.new res.body
    get_center = doc.root.elements[1].elements["center"]
    if not get_center.blank? 
      center_id =  doc.root.elements[1].elements["center"].get_text("id")
      params = {'center_id' => center_id }
      url = URI.parse("#{API_URL}/data_entry/payments/by_center.xml")
      req = Net::HTTP::Get.new(url.path)
      req.basic_auth 'admin', 'password'
      req.set_form_data(params)
      res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
      doc = REXML::Document.new res.body
      weeksheet = doc.root.elements[1].elements["weeksheet"]
      if not weeksheet.blank? 
        doc.root.elements[1].elements["weeksheet"].get_text("center_id").should == center_id
        res.code.should ==  "200"
      else
        doc.root.elements[1].get_text("error_code").should == "601"
      end
    end
  end

  it "Should be create client_group" do
    params = {'client_group[name]' => "test client group",'client_group[number_of_members]' => '1', 'client_group[code]' => '76533', 'client_group[center_id]' => '167' }
    url = URI.parse("#{API_URL}/client_groups.xml")
    req = Net::HTTP::Post.new(url.path)
    req.basic_auth 'admin', 'password'
    req.set_form_data(params)
    res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
    doc = REXML::Document.new res.body
    if doc.root.elements[1].elements["error"] != nil
      doc.root.elements[1].elements["error"].get_text("error_code").should == "600"
    else
      res.code.should == "200"
      doc.root.elements[1].elements["error"].should == nil
    end
  end

  it "Should be create center" do
    params = {'center[name]' => "test center",'center[code]' => '98761', 'center[manager_staff_id]' => '4', 'center[creation_date]' => '2011-04-11', 'center[branch_id]' => '1'  }
    url = URI.parse("#{API_URL}/centers.xml")
    req = Net::HTTP::Post.new(url.path)
    req.basic_auth 'admin', 'password'
    req.set_form_data(params)
    res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
    doc = REXML::Document.new res.body
    if doc.root.elements[1].elements["error"] != nil
      doc.root.elements[1].elements["error"].get_text("error_code").should == "600"
    else
      res.code.should == "200"
      doc.root.elements[1].elements["error"].should == nil
    end
  end

  it "Should be create attendance" do
    params = {'attendance[client_id]' => "167",'attendance[center_id]' => '11', 'attendance[status]' => 'present', 'attendance[date]' => '2011-04-11'}
    url = URI.parse("#{API_URL}/attendance.xml")
    req = Net::HTTP::Post.new(url.path)
    req.basic_auth 'admin', 'password'
    req.set_form_data(params)
    res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
    doc = REXML::Document.new res.body
    if doc.root.elements[1].elements["error"] != nil
      doc.root.elements[1].elements["error"].get_text("error_code").should == "600"
    else
      res.code.should == "200"
      doc.root.elements[1].elements["error"].should == nil
    end
  end

  it "Should be create client" do
    #branch = 1 and center = 11
    params = {'client[name]' => "test client",'client[reference]' => 'BK9238', 'client[date_joined]' => '2011-04-13', 'client[client_type_id]' => '1'}
    url = URI.parse("#{API_URL}/branches/1/centers/11/clients.xml")
    req = Net::HTTP::Post.new(url.path)
    req.basic_auth 'admin', 'password'
    req.set_form_data(params)
    res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
    doc = REXML::Document.new res.body
    if doc.root.elements[1].elements["error"] != nil
      doc.root.elements[1].elements["error"].get_text("error_code").should == "600"
    else
      res.code.should == "200"
      doc.root.elements[1].elements["error"].should == nil
    end
  end
end
