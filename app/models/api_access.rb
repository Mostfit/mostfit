class ApiAccess
  include DataMapper::Resource
  
  property :id, Serial
  property :origin, String, :nullable => false
  property :description, String, :nullable => false

  belongs_to :branch

  validates_is_unique   :origin
end
