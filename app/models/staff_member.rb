class StaffMember
  include DataMapper::Resource
  
  property :id,      Serial
  property :name,    String, :length => 100, :nullable => false
  property :active,  Boolean, :default => true, :nullable => false
  # no designations, they are derived from the relations it has

  has n, :branches
  has n, :centers, :child_key => [:manager_staff_id]
  has n, :approved_loans,    :child_key => [:approved_by_staff_id],    :class_name => 'Loan'
  has n, :disbursed_loans,   :child_key => [:disbursed_by_staff_id],   :class_name => 'Loan'
  has n, :written_off_loans, :child_key => [:written_off_by_staff_id], :class_name => 'Loan'


  validates_is_unique :name
  validates_length :name, :min => 3

end