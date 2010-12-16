class BranchDiary
  include DataMapper::Resource

  DAYS = [:none, :monday, :tuesday, :wednessday, :thursday, :friday, :saturday, :sunday]
  
  property :id,                      Serial
  property :name,                    String,                 :nullable => true,     :length => 100,         :index => true
  property :diary_date,              Date,                   :default => Date.today
  property :opening_time_hours,      Integer,                :nullable => false,    :length => 2,           :index => true
  property :opening_time_minutes,    Integer,                :nullable => false,    :length => 2,           :index => true
  property :closing_time_hours,      Integer,                :nullable => false,    :length => 2,           :index => true
  property :closing_time_minutes,    Integer,                :nullable => false,    :length => 2,           :index => true
  property :branch_opened_at,        DateTime,               :nullable => false,    :default => Time.now,   :index => true
  property :branch_closed_at,        DateTime,               :nullable => false,    :default => Time.now,   :index => true
  property :branch_key,              String,                 :nullable => false,    :length => 100,         :index => true
  property :branch_name,             String,                 :nullable => true,     :index => true
  property :branch_id,               Integer,                :nullable => false,    :index => true

  belongs_to  :manager,   :child_key =>[:manager_staff_id], :model => 'StaffMember'
  belongs_to  :branch,    :child_key =>[:branch_id],        :model => 'Branch'

  validates_present       :manager
  validates_with_method   :manager,       :method => :manager_is_an_active_staff_member?
  
  def self.from_csv(row, headers)
    obj = new(:name => row[headers[:name]], :manager => StaffMember.first(:name => row[headers[:manager]]))
    [obj.save, obj]
  end
  
  def self.search(q, per_page=10)
    if /^\d+$/.match(q)
      BranchDiary.all(:conditions => {:id => q}, :limit => per_page)
    else
      BranchDiary.all(:conditions => ["name like ?", q, q+'%'], :limit => per_page)
    end
  end

  private
  def manager_is_an_active_staff_member?
    return true if manager and manager.active
    [false, "Managing staff member is currently not active"]
  end
end
