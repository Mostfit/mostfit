class Holiday
  include DataMapper::Resource
  
  property :id, Serial

  property :name, String, :length => 50, :nullable => false
  property :date, Date, :nullable => false, :unique => true
  property :shift_meeting, Enum[:before, :after]

end
