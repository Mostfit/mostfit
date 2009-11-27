class StaffMember
  include DataMapper::Resource
  
  property :id,      Serial
  property :name,    String, :length => 100, :nullable => false
  property :mobile_number,  String, :length => 12,  :nullable => true
  property :active,  Boolean, :default => true, :nullable => false  
  # no designations, they are derived from the relations it has

  has n, :branches, :child_key => [:manager_staff_id]
  has n, :centers, :child_key => [:manager_staff_id]
  has n, :approved_loans,    :child_key => [:approved_by_staff_id],    :model => 'Loan'
  has n, :applied_loans,    :child_key => [:applied_by_staff_id],    :model => 'Loan'
  has n, :rejected_loans,    :child_key => [:rejected_by_staff_id],    :model => 'Loan'
  has n, :disbursed_loans,   :child_key => [:disbursed_by_staff_id],   :model => 'Loan'
  has n, :written_off_loans, :child_key => [:written_off_by_staff_id], :model => 'Loan'

  has n, :payments, :child_key  => [:received_by_staff_id]
  belongs_to :user
  validates_is_unique :name
  validates_length :name, :min => 3
  
  def self.from_csv(row, headers)
    user = User.new(:login => row[headers[:name]], :role => :staff_member, 
                    :password => row[headers[:password]], :password_confirmation => row[headers[:password]])    
    user.save
    obj = new(:name => row[headers[:name]], :user => user,
              :mobile_number => row[headers[:mobile_number]], 
              :active => true)
    [obj.save, obj]
  end
end
