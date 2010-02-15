class Area
  include DataMapper::Resource

  property :id, Serial
  property :name, Text

  has n, :branches
  belongs_to :region
  belongs_to :manager, :model => StaffMember

  validates_present :manager, :region
  validates_length :name, :min => 1

end
