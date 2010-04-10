class CenterHoliday
  include DataMapper::Resource
  
  property :id, Serial

  belongs_to :holiday
  belongs_to :center

end
