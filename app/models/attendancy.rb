class Attendancy
  include DataMapper::Resource
  
  ATTENDANCY_STATES = [:present, :on_leave, :absent, :proxy]

  property :id,              Serial
  property :date,            Date
  property :status,          Enum.send('[]', *ATTENDANCY_STATES), :nullable => false
  property :late,            Boolean, :nullable => false, :default => true

  belongs_to :client
  belongs_to :center

  def attendancy_states
    ATTENDANCY_STATES
  end
end
