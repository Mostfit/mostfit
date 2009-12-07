# class StaffAccount
#   include DataMapper::Resource
  
#   property :id, Serial
#   property :mobile_number, Integer, :nullable => false, :index => true
#   property :staff_member_id, Integer, :nullable => false, :index => true
#   property :account_id, Integer, :nullable => false, :index => true
# end
# This class needs to connect to mostfit_box db and keep adding mobile numbers to mostfit
