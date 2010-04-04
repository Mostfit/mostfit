# class StaffAccount
#   include DataMapper::Resource
  
#   property :id, Serial
#   property :mobile_number, Integer, :required => true, :index => true
#   property :staff_member_id, Integer, :required => true, :index => true
#   property :account_id, Integer, :required => true, :index => true
# end
# This class needs to connect to mostfit_box db and keep adding mobile numbers to mostfit
