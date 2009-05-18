class Report
  include DataMapper::Resource
  
  property :id, Serial
  property :name, Text, :length => 255

end
