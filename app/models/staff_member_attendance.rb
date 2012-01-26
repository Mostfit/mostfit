class StaffMemberAttendance
  include DataMapper::Resource

  ATTENDANCE_STATES = ["present", "late", "leave", "absent"]
  
  property :id,            Serial
  property :date,          Date, :index => true, :nullable => false
  property :status,        Enum.send('[]', *ATTENDANCE_STATES), :nullable => false, :index => true, :default => "present"
  property :created_at,    DateTime

  property :sma_branch_id, Integer, :index => true

  belongs_to :staff_member

  validates_with_method  :date, :method => :attendance_not_in_future?
  validates_is_unique    :date, :scope => :staff_member_id

  def self.attendance_states
    ATTENDANCE_STATES
  end

  def attendance_not_in_future?
    return true if date and (date<=Date.today)
    [false, "Attendance cannot be marked on future dates"]
  end

end
