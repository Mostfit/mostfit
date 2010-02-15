class Occupation
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :code, String, :length => 3

end