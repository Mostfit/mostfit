class Funder
  include DataMapper::Resource
  
  property :id,   Serial
  property :name, String, :length => 50, :nullable => false

  has n, :funding_lines

end
