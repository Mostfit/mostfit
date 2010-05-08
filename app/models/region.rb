class Region
  include DataMapper::Resource

  property :id, Serial
  property :name, Text
  property :address,              Text,   :lazy => true
  property :contact_number,       String, :length => 40, :lazy => true
  property :landmark,             String, :length => 100, :lazy => true  
  property :creation_date,        Date,   :length => 100, :lazy => true, :default => Date.today

  has n, :areas
  belongs_to :manager, :model => "StaffMember"

  validates_present :manager
  validates_is_unique :name
  validates_length :name, :max => 20, :min => 1

end
