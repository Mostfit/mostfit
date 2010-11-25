class Center
  include DataMapper::Resource
  include DateParser
  attr_accessor :meeting_day_change_date
  
  DAYS = [:none, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]
  after :save, :handle_meeting_date_change
  before :create, :set_meeting_change_date

  property :id,                   Serial
  property :name,                 String, :length => 100, :nullable => false, :index => true
  property :code,                 String, :length => 12, :nullable => true, :index => true
  property :address,              Text,   :lazy => true
  property :contact_number,       String, :length => 40, :lazy => true
  property :landmark,             String, :length => 100, :lazy => true  
  property :meeting_day,          Enum.send('[]', *DAYS), :nullable => false, :default => :none, :index => true
  property :meeting_time_hours,   Integer, :length => 2, :index => true
  property :meeting_time_minutes, Integer, :length => 2, :index => true
  property :created_at,           DateTime, :nullable => false, :default => Time.now, :index => true
  property :creation_date,        Date
  belongs_to :branch
  belongs_to :manager, :child_key => [:manager_staff_id], :model => 'StaffMember'

  has n, :clients
  has n, :client_groups
  has n, :loan_history
  has n, :center_meeting_days
  
  validates_is_unique   :code, :scope => :branch_id
  validates_length      :code, :min => 1, :max => 12

  validates_length      :name, :min => 3
  validates_present     :manager
  validates_present     :branch
  validates_with_method :meeting_time_hours,   :method => :hours_valid?
  validates_with_method :meeting_time_minutes, :method => :minutes_valid?

  def self.from_csv(row, headers)
    hour, minute = row[headers[:center_meeting_time_in_24h_format]].split(":")
    branch       = Branch.first(:name => row[headers[:branch_name]].strip)
    staff_member = StaffMember.first(:name => row[headers[:staff_name]])
    creation_date = ((headers[:creation_date] and row[headers[:creation_date]]) ? row[headers[:creation_date]] : Date.today)
    obj = new(:name => row[headers[:center_name]], :meeting_day => row[headers[:meeting_day]].downcase.to_s.to_sym, :code => row[headers[:code]],
              :meeting_time_hours => hour, :meeting_time_minutes => minute, :branch_id => branch.id, :manager_staff_id => staff_member.id,
              :creation_date => creation_date)
    [obj.save, obj]
  end

  def self.search(q, per_page=10)
    if /^\d+$/.match(q)
      all(:conditions => ["id = ? or code=?", q, q], :limit => per_page)
    else
      all(:conditions => ["code=? or name like ?", q, q+'%'], :limit => per_page)
    end
  end

  def self.meeting_days
    # Center.properties[:meeting_day].type.flag_map.values would give us a garbled order, so:
    DAYS
  end

  # a simple catalog (Hash) of center names and ids grouped by branches
  # returns some like: {"One branch" => {1 => 'center1', 2 => 'center2'}, "b2" => {3 => 'c3', 4 => 'c4'}} 
  def self.catalog(user=nil)
    result = {}
    branch_names = {}

    if user.staff_member
      staff_member = user.staff_member
      [staff_member.centers.branches, staff_member.branches].flatten.each{|b| branch_names[b.id] = b.name }
      centers = [staff_member.centers, staff_member.branches.centers].flatten
    else
      Branch.all(:fields => [:id, :name]).each{|b| branch_names[b.id] = b.name}
      centers = Center.all(:fields => [:id, :name, :branch_id])
    end
         
    centers.each do |center|
      branch = branch_names[center.branch_id]
      result[branch] ||= {}
      result[branch][center.id] = center.name
    end
    result
  end

  def meeting_day_for(date)
    @meeting_days ||= self.center_meeting_days(:order => [:valid_from])
    if @meeting_days.length==0
      meeting_day
    elsif date_row = @meeting_days.find{|md| md.valid_from <= date and md.valid_upto >= date} 
      date_row.meeting_day
    elsif @meeting_days[0].valid_from > date
      @meeting_days[0].meeting_day
    else
      @meeting_days[-1].meeting_day
    end
  end
    
  def next_meeting_date_from(date)
    number = get_meeting_date(date, :next)
    if (date + number - get_meeting_date(date + number, :previous)).cweek == (date + number).cweek
      (date + number + get_meeting_date(date + number, :next)).holiday_bump
    else
      (date + number).holiday_bump
    end
  end

  def previous_meeting_date_from(date)
    number = get_meeting_date(date, :previous)
    if (date - number - get_meeting_date(date - number, :previous)).cweek == (date - number).cweek
      (date - number - get_meeting_date(date - number, :previous)).holiday_bump
    else
      (date - number).holiday_bump
    end
  end


  def meeting_day?(date)
    x = LoanHistory.all(:date => date).map{|x| x.center_id}.uniq.include?(self.id)
    return x
  end

  def meeting_time
    meeting_time_hours.two_digits + ':' + meeting_time_minutes.two_digits
  end

  def self.paying_today(user, date = Date.today)
    center_ids = LoanHistory.all(:date => date||Date.today).map{|x| x.center_id}
    centers = center_ids.blank? ? [] : Center.all(:id => center_ids)
    centers
    if user.staff_member
      staff = user.staff_member
      centers = (staff.branches.count > 0 ? ([staff.centers, staff.branches.centers].flatten.uniq & centers) : (staff.centers & centers))
    end
    centers
  end
  
  def loans(hash={})
    self.clients.loans.all(hash)
  end
  
  def leader
    CenterLeader.first(:center => self, :current => true)
  end
  
  def leader=(id)
    if id
      client = Client.get(id)
      return if not client
      client.make_center_leader
    end
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

  def handle_meeting_date_change
    self.meeting_day_change_date = parse_date(self.meeting_day_change_date) if self.meeting_day_change_date.class==String and not self.meeting_day_change_date.blank?
    return if not self.meeting_day_change_date or self.meeting_day_change_date.blank?
    date = self.meeting_day_change_date||Date.today

    if not CenterMeetingDay.first(:center => self)
      CenterMeetingDay.create(:center_id => self.id, :valid_from => creation_date||date, :meeting_day => self.meeting_day)
    elsif self.meeting_day != self.meeting_day_for(date)
      if prev_cm = CenterMeetingDay.first(:center_id => self.id, :valid_from.lte => date, :order => [:valid_from.desc])
        # previous CMD should be valid upto date - 1
        prev_cm.valid_upto = date - 1
        prev_cm.save!
      end

      # next CMD's valid from date should be valid upto limit for this CMD
      if next_cm = CenterMeetingDay.first(:center => self, :valid_from.gt => date, :order => [:valid_from])
        valid_upto = next_cm.valid_from - 1
      else
        valid_upto = Date.new(2100, 12, 31)
      end
      CenterMeetingDay.create!(:center_id => self.id, :valid_from => date, :meeting_day => self.meeting_day, :valid_upto => valid_upto)
    end
    #clear cache
    @meeting_days = nil 
    self.reload.clients.loans.each{|l|
      if [:outstanding, :disbursed].include?(l.status)
        l.update_history
      end
    }
    return true
  end  


  def set_meeting_change_date
    self.meeting_day_change_date = self.creation_date
  end

  def get_meeting_date(date, direction)
    number = 1
    if direction == :next
      nwday = (date + number).wday
      while nwday != Center.meeting_days.index(meeting_day_for(date + number))
        number += 1
        nwday = (date + number).wday
        nwday = 7 if nwday == 0
      end
    else
      nwday = (date + number).wday
      while (date - number).wday != Center.meeting_days.index(meeting_day_for(date - number))
        number += 1
        nwday = (date - number).wday
        nwday = 7 if nwday == 0
      end
    end
    return number
  end

end
