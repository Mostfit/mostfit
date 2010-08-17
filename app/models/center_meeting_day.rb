class CenterMeetingDay
  include DataMapper::Resource
  DAYS = [:none, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]
  
  property :id, Serial
  property :center_id, Integer, :index => false, :nullable => false
  property :meeting_day, Enum.send('[]', *DAYS), :nullable => false, :default => :none, :index => true
  property :valid_from,  Date, :nullable => false
  property :valid_upto,  Date, :nullable => false, :default => Date.new(2100, 12, 31) # a date far in future
  belongs_to :center

  validates_with_method :valid_from_is_lesser_than_valid_upto
  
  def valid_from_is_lesser_than_valid_upto
    if self.valid_from and self.valid_upto
      return [false, "Valid from date cannot be before than valid upto date"] if self.valid_from > self.valid_upto
      return true    
    end
  end
end
