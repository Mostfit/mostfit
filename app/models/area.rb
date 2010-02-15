class Area
  include DataMapper::Resource

  property :id, Serial
  property :name, Text

  has n, :branches
  belongs_to :region

end
