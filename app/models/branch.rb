class Branch
  extend Reporting::BranchReports
  include DataMapper::Resource

  property :id,      Serial
  property :name,    String, :length => 100, :nullable => false, :index => true
  property :code,    String, :length => 10, :nullable => true, :index => true, :min => 1, :max => 10
  property :address, Text
  property :created_at, DateTime
  
  belongs_to :manager, :child_key => [:manager_staff_id], :model => 'StaffMember'
  has n, :centers

  validates_is_unique   :code
  validates_length      :code, :min => 1, :max => 10

  validates_length      :name, :min => 3
  validates_present     :manager
  validates_with_method :manager, :method => :manager_is_an_active_staff_member?

  def self.from_csv(row, headers)
    obj = new(:code => row[headers[:code]], :name => row[headers[:name]], :address => row[headers[:address]], :manager_staff_id => StaffMember.first(:name => row[headers[:manager]]).id) 
    [obj.save, obj]
  end
  
  def centers_with_paginate(params)
    centers.paginate(:page => params[:page], :per_page => 15)
  end

  def self.search(q)
    if /^\d+$/.match(q)
      Branch.all(:conditions => {:id => q})
    else
      Branch.all(:conditions => ["code=? or name like ?", q, q+'%'])
    end
  end

  private
  def manager_is_an_active_staff_member?
    return true if manager and manager.active
    [false, "Managing staff member is currently not active"]
  end
end
