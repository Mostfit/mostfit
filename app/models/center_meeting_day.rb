class CenterMeetingDay

  include DataMapper::Resource
  DAYS = [:none, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]

  after :destroy, :fix_dates
  after :save,    :add_loans_to_queue

  property :id, Serial
  property :center_id, Integer, :index => false, :nullable => false
  property :meeting_day, Enum.send('[]', *DAYS), :nullable => false, :default => :none, :index => true
  property :valid_from,  Date, :nullable => false
  property :valid_upto,  Date, :nullable => true # we do not really need valid upto.  CMDs are valid up to the next center meeting days start from
  
  property :deleted_at,  ParanoidDateTime
  
  # define some properties using which we can construct a DateVector of meeting dates
  # see lib/date_vector.rb for details but in short one can say things like
  # :every => [2,4], :what => :thursday, :of_every => 2, :period => :month to mean "every 2nd and 4th thursday of every 2nd month"
  # this is the kind of feature that sets Mostfit miles apart from the rest of the pack!

  property :every, CommaSeparatedList 
  property :what, CommaSeparatedList
  property :of_every, Integer
  property :period, Enum[:week, :month]
  
  belongs_to :center

  before :valid?, :convert_blank_to_nil

  def check_not_last
    raise ArgumentError.new("Cannot delete the only center meeting schedule") if self.center.center_meeting_days.count == 1
  end
  

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

  def meeting_day_string
    return "every #{every} #{what.join(',')} of every #{of_every} #{period}" unless [every,what,of_every,period].include?(nil)
    return meeting_day.to_s

  end

  def to_s
    "from #{valid_from} to #{valid_upto} : #{meeting_day_string}"
  end

  after :destroy, :fix_dates


  validates_with_method :valid_from_is_lesser_than_valid_upto
  validates_with_method :dates_do_not_overlap
  validates_with_method :check_not_last, :if => Proc.new{|t| t.deleted_at}

  def check_not_last
    return true unless center
    return true unless deleted_at
    return [false,"cannot delete the last center meeting date"] if (self.center.center_meeting_days.count == 1 and (self.center.meeting_day == :none or (not self.center.meeting_day)))
  end
  
  def last_date
    valid_upto || Date.new(2100,12,31)
  end


  def date_vector(from = self.valid_from, to = last_date)
    if every and what and of_every and period
      DateVector.new(every, what.map{|w| w.to_sym}, of_every, period.to_sym, from, to)
    else
      DateVector.new(1,meeting_day, 1, :week, from, to)
    end
  end

  def get_dates(from = self.valid_from, to = last_date)
    date_vector(from, to).get_dates
  end

  def get_next_n_dates(n, from = self.valid_from)
    get_dates(from, n)
  end

  def meeting_day_string
    return meeting_day.to_s if meeting_day and meeting_day != :none
    "every #{every} #{(what or Nothing).join(',')} of every #{of_every} #{period}"
  end

  def to_s
    "from #{valid_from} to #{valid_upto} : #{meeting_day_string}"
  end

  
  def valid_from_is_lesser_than_valid_upto
    self.valid_from = Date.parse(self.valid_from) unless self.valid_from.is_a? Date
    self.valid_upto = (self.valid_upto.blank? ? Date.new(2100,12,31) : Date.parse(self.valid_upto))     if self.valid_upto.class == String

    if self.valid_from and self.valid_upto
      return [false, "Valid from date cannot be before than valid upto date"] if self.valid_from > self.valid_upto
    end
    return true    

  end

  # checks that for a given center, the valid_from and valid_to dates for this center do not overlap with another center_meeting_day
  def dates_do_not_overlap
    return true if deleted_at
    return true unless self.center
    cmds = self.center.center_meeting_days
    return true if cmds.count == 0
    return true if cmds.count == 1 and cmds.first.id == self.id
    bad_ones = center.center_meeting_days.map do |cmd| 
      if cmd.id == id
        true
      else
        if cmd.valid_upto and cmd.valid_upto != Date.new(2100,12,31) # an end date is specified for the other cmd 
          if valid_upto  and valid_upto != Date.new(2100,12,31)          # and for ourselves
            cmd.valid_from > valid_upto or cmd.valid_upto < valid_from # either we end before the other one starts or start after the other one ends
          else            # but not for ourselves
            valid_from > cmd.valid_upto or valid_from < cmd.valid_from # either we start after the other one starts or we start after the other one ends
          end
        else                 # no end date specified for the other one
          if valid_upto and  valid_upto != Date.new(2100,12,31)     # but we have one
            valid_from > cmd.valid_from or valid_upto < cmd.valid_from  # either we start after the other one starts or we end before the other one starts
          else               # neither one has an end date
            true
          end
        end
      end
    end
    return [false, "Center Meeting Day validity overlaps with another center meeting day."] if bad_ones.select{|x| not x}.count > 0
    return true
  end


  # adds the loans from this center into the dirty_loan queue to recreate their history
  def add_loans_to_queue
    loan_ids = self.center.loans.aggregate(:id) rescue nil
    return if loan_ids.blank?
    now = DateTime.now
    repository.adapter.execute(get_bulk_insert_sql("dirty_loans", loan_ids.map{|pl| {:loan_id => pl, :created_at => now}}))
    DirtyLoan.send(:class_variable_set,"@@poke_thread", true)
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

  def convert_blank_to_nil
    self.attributes.each{|k, v|
      if v.is_a?(String) and v.empty? and self.class.properties.find{|x| x.name == k}.type==Integer
        self.send("#{k}=", nil)
      end
    }
  end


end
