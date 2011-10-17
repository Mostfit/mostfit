class HolidaysFor

  include DataMapper::Resource
  
  property :holiday_id,          Integer, :key => true
  property :holiday_calendar_id, Integer, :key => true

  belongs_to :holiday
  belongs_to :holiday_calendar


end
