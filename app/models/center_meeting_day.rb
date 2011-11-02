class CenterMeetingDay

  include DataMapper::Resource
  DAYS = [:none, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]
  
  property :id, Serial
  property :center_id, Integer, :index => false, :nullable => false
  property :meeting_day, Enum.send('[]', *DAYS), :nullable => false, :default => :none, :index => true
  property :valid_from,  Date, :nullable => false
  property :valid_upto,  Date, :nullable => false, :default => Date.new(2100, 12, 31) # a date far in future
  
  # define some properties using which we can construct a DateVector of meeting dates
  # see lib/date_vector.rb for details but in short one can say things like
  # :every => [2,4], :what => :thursday, :of_every => 2, :period => :month to mean "every 2nd and 4th thursday of every 2nd month"
  # this is the kind of feature that sets Mostfit miles apart from the rest of the pack!

  property :every, CommaSeparatedList 
  property :what, CommaSeparatedList
  property :of_every, Integer
  property :period, Enum[:week, :month]
  
  belongs_to :center

  

  # adding the new properties to calculate the datevector for this center.
  # for now we will allow only one datevector type per center. This means a center can only have one meeting schedule frequency
  
  def date_vector(from = self.valid_from, to = self.valid_upto)
    DateVector.new(every, what.map{|w| w.to_sym}, of_every, period.to_sym, from, to)
  end

  def get_dates(from = self.valid_from, to = self.valid_upto)
    date_vector(from, to).get_dates
  end

  def get_next_n_dates(n, from = self.valid_from)
    get_dates(from, n)
  end

  after :destroy, :fix_dates


  validates_with_method :valid_from_is_lesser_than_valid_upto
  
  def valid_from_is_lesser_than_valid_upto
    if self.valid_from and self.valid_upto
      return [false, "Valid from date cannot be before than valid upto date"] if self.valid_from > self.valid_upto
      return true    
    end
  end

  def fix_dates
    cmds = CenterMeetingDay.all(:order => [:valid_from], :center_id => self.center_id)
    cmds.each_with_index{|cmd, idx|
      cmd.valid_upto=Date.new(2100, 12, 31) if cmds.length - 1 == idx
      
      if idx==0
        if cmd.valid_from>cmd.center.creation_date
          cmd.valid_from=cmd.center.creation_date
        end
      else
        if cmds[idx-1].valid_upto+1 != cmd.valid_from
          cmd.valid_from = cmds[idx-1].valid_upto+1
        end
      end
      cmd.save
    }
    # fix center meeting day
    cen = Center.get(self.center_id)
    if cen.meeting_day != cen.meeting_day_for(Date.today)
      cen.meeting_day  = cen.meeting_day_for(Date.today)
      cen.save
    end
  end
end
