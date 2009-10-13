class Branch
  include DataMapper::Resource
  extend Reporting::BranchReports

  property :id,      Serial
  property :name,    String, :length => 100, :nullable => false
  property :address, Text
  
  belongs_to :manager, :child_key => [:manager_staff_id], :class_name => 'StaffMember'
  has n, :centers

  validates_length      :name, :min => 3
  validates_present     :manager
  validates_with_method :manager, :method => :manager_is_an_active_staff_member?

  
  def centers_with_paginate(params)
    centers.paginate(:page => params[:page], :per_page => 15)
  end

  def self.search(q)
    if /^\d+$/.match(q)
      Branch.all(:conditions => {:id => q})
    else
      Branch.all(:conditions => ["name like ?", q+'%'])
    end
  end

  private
  def manager_is_an_active_staff_member?
    return true if manager and manager.active
    [false, "Managing staff member is currently not active"]
  end
end
