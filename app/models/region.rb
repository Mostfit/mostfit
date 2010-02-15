class Region
  include DataMapper::Resource

  property :id, Serial
  property :name, Text

  has n, :areas

end
