require 'rubygems'
require 'dm-core'
require 'branch'
require 'center'
require 'payment'
require "uri"
require 'httparty'

DataMapper::Logger.new($stdout, :debug)
params = {
  :adapter => 'rest',
  :login => 'admin',
  :format => 'xml',
  :user => 'admin',
  :password => 'password',
  :host => 'localhost',
  :port => 4000
}
DataMapper.setup(:default, params)

#get branches
branches = Branch.all
branches.each { |branch| puts branch.name }

#get centers
centers = Center.all
centers.each { |center| puts center.name }

#create payment checking using httparty request
#branch: 1, center : 11, client :167, loans : 199

res = Payment.make_payment(1,11,167,199)
        puts "Payment created"
	puts res['payment']["message"]
	puts res['payment']["id"]
	puts res['payment']["type"]
	puts res['payment']["amount"]
	puts res['payment']["received_on"]
	puts "----------------"




#~ url = URI.parse('http://localhost:4000/branches.xml')
#~ req = Net::HTTP::Get.new(url.path)
#~ req.basic_auth 'admin', 'password'

#~ res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
#~ puts res.body




