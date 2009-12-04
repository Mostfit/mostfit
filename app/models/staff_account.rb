class StaffAccount
  include DataMapper::Resource
  
  property :id, Serial
  property :mobile_number, Integer, :nullable => false, :index => true
  property :staff_member_id, Integer, :nullable => false, :index => true
  property :account_id, Integer, :nullable => false, :index => true
end
