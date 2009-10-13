class Center
  include DataMapper::Resource

  DAYS = [:none, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]
  
  property :id,                   Serial
  property :name,                 String, :length => 100, :nullable => false
  property :center_leader_name,   String, :length => 100
  property :meeting_day,          Enum.send('[]', *DAYS), :nullable => false, :default => :none
  property :meeting_time_hours,   Integer, :length => 2
  property :meeting_time_minutes, Integer, :length => 2

  belongs_to :branch
  belongs_to :manager, :child_key => [:manager_staff_id], :class_name => 'StaffMember'

  has n, :clients

  validates_length      :name, :min => 3
  validates_present     :manager
  validates_present     :branch
  validates_with_method :meeting_time_hours,   :method => :hours_valid?
  validates_with_method :meeting_time_minutes, :method => :minutes_valid?

  def self.search(q)
    if /^\d+$/.match(q)
      all(:conditions => {:id => q})
    else
      all(:conditions => ["name like ? or center_leader_name like ?", q+'%', q+'%'])
    end
  end

  def self.meeting_days
    # Center.properties[:meeting_day].type.flag_map.values would give us a garbled order, so:
    DAYS
  end

  # a simple catalog (Hash) of center names and ids grouped by branches
  # returns some like: {"One branch" => {1 => 'center1', 2 => 'center2'}, "b2" => {3 => 'c3', 4 => 'c4'}} 
  def self.catalog
    result = {}
    branch_names = {}
    Branch.all(:fields => [:id, :name]).each { |b| branch_names[b.id] = b.name }
    Center.all(:fields => [:id, :name, :branch_id]).each do |center|
      branch = branch_names[center.branch_id]
      result[branch] ||= {}
      result[branch][center.id] = center.name
    end
    result
  end

  def next_meeting_date_from(date)
    meeting_wday = Center.meeting_days.index(meeting_day)
    next_meeting_date = date - date.wday + meeting_wday
    next_meeting_date += 7 if next_meeting_date <= date
    next_meeting_date
  end

  def previous_meeting_date_from(date)
    meeting_wday = Center.meeting_days.index(meeting_day)
    previous_meeting_date = date - date.wday + meeting_wday - 7
    previous_meeting_date -= 7 if previous_meeting_date >= date
    previous_meeting_date
  end


  def meeting_day?(date)
    date.cwday == Center.meeting_days.index(meeting_day)
  end

  def meeting_time
    meeting_time_hours.two_digits + ':' + meeting_time_minutes.two_digits
  end

  private
  def hours_valid?
    return true if meeting_time_hours.blank? or (0..23).include? meeting_time_hours.to_i
    [false, "Hours of the meeting time should be within 0-23 or blank"]
  end
  def minutes_valid?
    return true if meeting_time_minutes.blank? or (0..59).include? meeting_time_minutes.to_i
    [false, "Minutes of the meeting time should be within 0-59 or blank"]
  end
  def manager_is_an_active_staff_member?
    return true if manager and manager.active
    [false, "Receiving staff member is currently not active"]
  end
end
