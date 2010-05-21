class StaffMember
  include DataMapper::Resource
  
  property :id,      Serial
  property :name,    String, :length => 100, :nullable => false
  property :mobile_number,  String, :length => 12,  :nullable => true
  property :creation_date,  Date, :length => 12,  :nullable => true, :default => Date.today
  property :active,  Boolean, :default => true, :nullable => false  
  property :user_id,  Integer,  :nullable => true  
  # no designations, they are derived from the relations it has

  has n, :branches,          :child_key => [:manager_staff_id]
  has n, :centers,           :child_key => [:manager_staff_id]
  has n, :regions,           :child_key => [:manager_id]
  has n, :areas,             :child_key => [:manager_id]
  has n, :approved_loans,    :child_key => [:approved_by_staff_id],    :model => 'Loan'
  has n, :applied_loans,     :child_key => [:applied_by_staff_id],    :model => 'Loan'
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
    obj = new(:name => row[headers[:name]], :user => user, :creation_date => Date.today,
              :mobile_number => row[headers[:mobile_number]], 
              :active => true)
    [obj.save, obj]
  end

  def clients
    Client.all(:created_by_staff_member_id => self.id)
  end

  def loans
    Loan.all(:applied_by_staff_id => self.id)
  end

  def client_groups
    ClientGroup.all(:created_by_staff_member_id => self.id)
  end
  
  def self.related_to(obj)
    staff_members = []    
    [:applied_by_staff_id, :approved_by_staff_id, :rejected_by_staff_id, :disbursed_by_staff_id, :written_off_by_staff_id].each{|type|
      staff_members << if obj.class==Branch
                         repository.adapter.query(%Q{SELECT distinct(#{type}) FROM branches b, centers c, clients cl, loans l
                                                    WHERE b.id=#{obj.id} and c.branch_id=b.id and cl.center_id=c.id and l.client_id=cl.id})
                       elsif obj.class==Center
                         repository.adapter.query(%Q{SELECT distinct(#{type}) FROM centers c, clients cl, loans l
                                                    WHERE c.id=#{obj.id} and cl.center_id=c.id and l.client_id=cl.id})
                       elsif obj.class==Client
                         repository.adapter.query(%Q{SELECT distinct(#{type}) FROM centers c, clients cl, loans l
                                                    WHERE cl.id=#{obj.id} and l.client_id=cl.id})
                       end 
    }
    staff_members = staff_members.flatten.uniq.compact
    staff_members.delete(0)
    return staff_members
  end
end
