require 'rubygems'
require 'httparty'
class Payment
  include DataMapper::Resource
    
  property :id,     Serial
  property :amount,  String
  property :type,  String
  property :loan_id,  Integer
  property :client_id,  Integer
  property :received_by_staff_id,  Integer
  property :received_on,  Date

  #using httparty call mostfit api
  include HTTParty
  base_uri 'http://localhost:4000/api/v1'
  basic_auth 'admin', 'password'
  format :xml
  
  #branch: 1, center : 11, client :167, loans : 199
  def self.make_payment(branch,center,client,loan)
    post("/branches/#{branch}/centers/#{center}/clients/#{client}/loans/#{loan}/payments.xml", :query => {:payment => {:amount =>99.06, :type =>:principal, :loan_id => loan, :client_id => client, :received_by_staff_id =>1, :received_on => "2011-03-28"}})
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