class ClientGroup
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String, :nullable => false
  property :number_of_members, Integer, :nullable => false, :min => 1, :max => 20  

  has n, :clients
  belongs_to :center
  validates_is_unique :name, :scope => :center_id  
end
