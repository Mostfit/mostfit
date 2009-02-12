class Center
  include DataMapper::Resource

  DAYS = [:none, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]
  
  property :id,                   Serial
  property :name,                 String, :length => 100, :nullable => false
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

  def self.meeting_days
    # Center.properties[:meeting_day].type.flag_map.values would give us a garbled order, so:
    DAYS
  end

  private
  def hours_valid?
    return true if meeting_time_hours.blank? or (0..23).include? meeting_time_hours.to_i
    [false, "hours of the meeting time should be within 0-23 or blank"]
  end
  def minutes_valid?
    return true if meeting_time_minutes.blank? or (0..59).include? meeting_time_minutes.to_i
    [false, "hours of the meeting time should be within 0-59 or blank"]
  end
  def manager_is_an_active_staff_member?
    return true if manager and manager.active
    [false, "receiving staff member is currently not active"]
  end
end
