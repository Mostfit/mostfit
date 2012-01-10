class Branch
  include DataMapper::Resource
  include Comparable
  extend Reporting::BranchReports

  before :save, :convert_blank_to_nil
  
  property :id,      Serial
  property :name,    String, :length => 100, :nullable => false, :index => true
  property :code,    String, :length => 10, :nullable => true, :index => true, :min => 1, :max => 10
  property :address, Text,   :lazy => true
  property :contact_number, String, :length => 40, :lazy => true
  property :landmark,       String, :length => 100, :lazy => true  
  property :created_at,     DateTime
  property :creation_date,  Date, :default => Date.today
  property :area_id,        Integer, :nullable => true

  belongs_to :manager,      :child_key => [:manager_staff_id], :model => 'StaffMember'
  belongs_to :area,         :nullable => true
  has n, :centers
  has n, :audit_trails, :auditable_type => "Branch", :child_key => ["auditable_id"]
  has n, :accounts
  has n, :api_accesses

  belongs_to :organization, :parent_key => [:org_guid], :child_key => [:parent_org_guid], :required => false
  
  property   :parent_org_guid, String, :nullable => true
  
  belongs_to :domain, :parent_key => [:domain_guid], :child_key => [:parent_domain_guid], :required => false
  property   :parent_domain_guid, String, :nullable => true

  validates_is_unique   :code
  validates_is_unique   :name
  validates_length      :code, :min => 1, :max => 10

  validates_length      :name, :min => 3
  validates_present     :manager
  validates_with_method :manager, :method => :manager_is_an_active_staff_member?

  def self.from_csv(row, headers)
    obj = new(:code => row[headers[:code]], :name => row[headers[:name]], :address => row[headers[:address]], 
              :manager => StaffMember.first(:name => row[headers[:manager]]), :upload_id => row[headers[:upload_id]])
    [obj.save, obj]
  end

  def centers_with_paginate(params, user)
    hash = {:order => [:meeting_day, :meeting_time_hours, :meeting_time_minutes]}
    # This the logged in person is a staff member and he is not a branch manager
    hash[:branch] = self

    if staff = user.staff_member and not staff==self.manager
      if not staff.branches.include?(self) and not staff.areas.branches.include?(self) and not staff.regions.areas.branches.include?(self)
        hash[:manager] = user.staff_member
      end
    elsif user.role == :funder 
      hash[:id] = Funder.first(:user_id => user.id).centers({:branch_id => self.id}).map{|c| c.id}
    end
    branch_center_ids = self.centers.aggregate(:id)
    mday = (params[:meeting_day] or Nothing).to_sym || Date.today.weekday
    if Center::DAYS.include?(mday)
      # either the meeting day is set directly on the center_meeting_day
      # or it is set on the "what" property. effing backward compatibility!
      cids = self.centers.center_meeting_days(:valid_from.lte => Date.today, :valid_upto.gte => Date.today, :meeting_day => mday, :what => nil).aggregate(:center_id) +
        self.centers.center_meeting_days(:valid_from.lte => Date.today, :valid_upto.gte => Date.today, :what => mday, :meeting_day => :none).aggregate(:center_id)
      #cids += (self.centers.center_meeting_days(:valid_from.lte => Date.today, :valid_upto.gte => Date.today, :what => mday).aggregate(:center_id) &
      #         self.centers.center_meeting_days(:valid_from.lte => Date.today, :valid_upto.gte => Date.today, :meeting_day => :none).aggregate(:center_id))
      to_be_ignored = self.centers.center_meeting_days(:valid_from.lte => Date.today, :valid_upto.gte => Date.today).aggregate(:center_id)
      cids += Center.all(:id => branch_center_ids, :meeting_day => mday).aggregate(:id) - to_be_ignored
    end
    hash[:id]= cids
    Center.all(hash)
  end

  def client_groups(hash={})
    self.centers.client_groups(hash)
  end

  def clients(hash={})
    self.centers.clients(hash)
  end

  def loans(hash={})
    self.centers.clients.loans(hash)
  end

  def self.search(q, per_page=10)
    if /^\d+$/.match(q)
      Branch.all(:conditions => {:id => q}, :limit => per_page)
    else
      Branch.all(:conditions => ["code=? or name like ?", q, q+'%'], :limit => per_page)
    end
  end
  
  def client_ids
    repository.adapter.query(%Q{
                                SELECT cl.id clid
                                FROM branches b, centers c, clients cl
                                WHERE b.id=#{self.id} AND b.id=c.branch_id AND c.id=cl.center_id AND cl.deleted_at is NULL
                             })    
  end

  def location
    Location.first(:parent_id => self.id, :parent_type => "branch")
  end

  def self.for_staff_member(staff_member)
    branches = Branch.all(:manager => staff_member).aggregate(:id) + Branch.all("centers.manager_staff_id" => staff_member.id).aggregate(:id) + 
      Branch.all("area.manager_id" => staff_member.id).aggregate(:id) + Branch.all("area.region.manager_id" => staff_member.id).aggregate(:id)
    Branch.all(:id => branches)
  end
  
  def holidays
    # go up the chain and find the first calendar that applies.
    hc = HolidayCalendar.all(:branch_id => id)
    hc = HolidayCalendar.all(:area_id => area_id) if hc.blank?
    hc = HolidayCalendar.all(:region_id => area.region_id) if (hc.blank? and area)
    hc.holidays_fors.holidays
  end

  private
  def manager_is_an_active_staff_member?
    return true if manager and manager.active
    [false, "Managing staff member is currently not active"]
  end

  def convert_blank_to_nil
    self.attributes.each{|k, v|
      if v.is_a?(String) and v.empty? and self.class.properties.find{|x| x.name == k}.type==Integer
        self.send("#{k}=", nil)
      end
    }
  end
  

  def <=> (other)
    @name <=> other.name
  end


end
