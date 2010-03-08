class Grt
  include DataMapper::Resource
  
  property :id, Serial
  property :date, Date, :nullable => false
  property :passed, Boolean, :default => false

  belongs_to :client_group

end
