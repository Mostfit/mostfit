class BranchDiary
  include DataMapper::Resource
  before :save, :convert_blank_to_nil

  property :id,                      Serial
  property :name,                    String,                 :nullable => true,    :length => 100,         :index => true
  property :diary_date,              Date,                   :nullable => false,   :default => Date.today
  property :opening_time_hours,      Integer,                :nullable => false,   :length => 2,           :index => true
  property :opening_time_minutes,    Integer,                :nullable => false,   :length => 2,           :index => true
  property :closing_time_hours,      Integer,                :nullable => true,    :length => 2,           :index => true
  property :closing_time_minutes,    Integer,                :nullable => true,    :length => 2,           :index => true
  property :branch_opened_at,        DateTime,               :nullable => false,   :default => Time.now,   :index => true
  property :branch_closed_at,        DateTime,               :nullable => false,   :default => Time.now,   :index => true
  property :branch_key,              String,                 :nullable => false,   :length => 100,         :index => true
  property :branch_name,             String,                 :nullable => true,    :index => true
  property :branch_id,               Integer,                :nullable => false,   :index => true

  belongs_to  :manager,   :child_key =>[:manager_staff_id], :model => 'StaffMember'
  belongs_to  :branch,    :child_key =>[:branch_id],        :model => 'Branch'

  validates_present       :manager
  validates_with_method   :manager,    :method => :manager_is_an_active_staff_member?
  validates_is_unique     :diary_date, :scope => :branch_id
  
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
end
