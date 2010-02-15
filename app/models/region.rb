class Region
  include DataMapper::Resource

  property :id, Serial
  property :name, Text

  has n, :areas
  belongs_to :manager, :model => "StaffMember"

  validates_present :manager
  validates_length :name, :max => 20, :min => 1

end
