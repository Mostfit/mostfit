require "rubygems"
require "uri"

url = URI.parse('http://localhost:4000/browse.xml')
req = Net::HTTP::Get.new(url.path)
req.basic_auth 'apilogin', 'apilogin'

res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
case res
when Net::HTTPSuccess, Net::HTTPRedirection
  puts "logged on"
  puts res.body
else
  res.error!
end
