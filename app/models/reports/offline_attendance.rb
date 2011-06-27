class OfflineAttendance < Report
  attr_accessor :from_date, :to_date
  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today    
    @name   = "Report from #{@from_date} to #{@to_date}"
    get_parameters(params, user)
  end

  def name
    "Offline Attendance"
  end

  def self.name
    "Offline Attendance"
  end

  def generate
    data = []
    hash = {:date.gte => from_date, :date.lte => to_date}
    #hash[:center_id] = center_id if center_id
    Attendance.all(hash).each do |attendance|
      data.push([attendance.date, attendance.id, attendance.client.name, attendance.status, attendance.center.name, attendance.desktop_id, attendance.origin])
    end
    return data
  end
end
