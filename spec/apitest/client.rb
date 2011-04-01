require 'rubygems'
require 'httparty'
require "base64"
class Client
  include DataMapper::Resource
    
  property :id,     Serial
  property :name,  String
  property :document,  String
  

  #using httparty call mostfit api
  include HTTParty
  base_uri 'http://localhost:4000'
  basic_auth 'admin', 'password'
  format :xml
  
  #branch: 1, center : 8, client :119
  def self.update_client(branch,center,client)
    image = Base64.encode64("#{File.read('/home/kiran/Desktop/sample.fpt')}") 
    
    put("/api/v1/branches/#{branch}/centers/#{center}/clients/#{client}.xml", :query => {:client => {:name =>"kiran1", :fingerprint => image}})
  end
  
end

#~ class Payment
 #~ include DataMapper::Resource
 
 #~ property :local_id,                Serial
 #~ property :id,                        Integer
 #~ property :amount,             Float
 #~ property :comment,            String, :length => 50
 #~ property :received_on,        Date
 #~ property :received_by_staff_id, Integer
 #~ property :created_at,         DateTime, :default => Time.now
 #~ property :created_by_user_id, Integer
 #~ property :loan_id,            Integer
 #~ property :client_id,          Integer
 #~ property :weeksheet_row_id,        Integer

 #~ belongs_to :loan
 #~ belongs_to :client
 #~ belongs_to :created_by,  :child_key => [:created_by_user_id],   :model => 'User'
 #~ belongs_to :received_by, :child_key => [:received_by_staff_id], :model => 'StaffMember'
 #~ belongs_to :from_weeksheet_row, :child_key => [:weeksheet_row_id], :model => 'WeeksheetRow'
#~ end