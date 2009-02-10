class Branch
  include DataMapper::Resource
  
  property :id,      Serial
  property :name,    String, :length => 100, :nullable => false
  property :address, Text
  
  belongs_to :manager, :child_key => [:manager_staff_id], :class_name => 'StaffMember'
  has n, :centers

  validates_length  :name, :min => 3
  validates_present :manager
end