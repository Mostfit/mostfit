class Batch
  include DataMapper::Resource
  
  property :id,              Serial
  property :creation_time,    DateTime

end
