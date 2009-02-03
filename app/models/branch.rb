class Branch
  include DataMapper::Resource
  
  property :id,      Serial
  property :name,    String, :length => 100, :nullable => false
  property :address, Text
  
  belongs_to :manager, :child_key => [:manager_staff_id], :class_name => 'StaffMember'
  has n, :centers

  validates_present :manager_staff_id

  def loan_stats
    Loan.loan_stats_for self.centers.clients.loans
  end
end