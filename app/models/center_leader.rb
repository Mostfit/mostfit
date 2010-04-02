class CenterLeader
  include DataMapper::Resource
  
  property :id, Serial
  property :client_id, Integer, :nullable => false, :index => true
  property :center_id, Integer, :nullable => false, :index => true
  property :date_assigned, Date, :nullable => false, :index => true
  property :date_deassigned, Date, :nullable => true, :index => true
  property :current, Boolean, :nullable => true, :index => true, :default => true
  
  belongs_to :center
  belongs_to :client
end
