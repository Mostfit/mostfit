class Area
  include DataMapper::Resource

  property :id, Serial
  property :name, Text
  property :address,              Text,   :lazy => true
  property :contact_number,       String, :length => 40, :lazy => true
  property :landmark,             String, :length => 100, :lazy => true  
  property :creation_date,        Date,   :length => 100, :lazy => true, :default => Date.today

  has n, :branches
  belongs_to :region
  belongs_to :manager, :model => StaffMember

  validates_is_unique :name, :scope => [:region]
  validates_present :manager, :region
  validates_length :name, :min => 1

end
