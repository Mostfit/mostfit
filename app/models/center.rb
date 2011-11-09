class Center
  include DataMapper::Resource
  include DateParser

  attr_accessor :meeting_day_change_date

  before :save, :convert_blank_to_nil
  after  :save, :handle_meeting_date_change
  before :save, :set_meeting_change_date
  before :create, :set_meeting_change_date
  before :valid?, :convert_blank_to_nil

  
  DAYS = [:none, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]

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
  has n, :weeksheets
  
  validates_is_unique   :code, :scope => :branch_id
  validates_length      :code, :min => 1, :max => 12

  validates_length      :name, :min => 3
  validates_is_unique   :name
  validates_present     :manager
  validates_present     :branch
  validates_with_method :meeting_time_hours,   :method => :hours_valid?
  validates_with_method :meeting_time_minutes, :method => :minutes_valid?


  def self.from_csv(row, headers)
    hour, minute = row[headers[:center_meeting_time_in_24h_format]].split(":")
    branch       = Branch.first(:name => row[headers[:branch]].strip)
    staff_member = StaffMember.first(:name => row[headers[:manager]])

    creation_date = ((headers[:creation_date] and row[headers[:creation_date]]) ? row[headers[:creation_date]] : Date.today)
    obj = new(:name => row[headers[:center_name]], :meeting_day => row[headers[:meeting_day]].downcase.to_s.to_sym, :code => row[headers[:code]],
              :meeting_time_hours => hour, :meeting_time_minutes => minute, :branch_id => branch.id, :manager_staff_id => staff_member.id,
              :creation_date => creation_date, :upload_id => row[headers[:upload_id]])
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
    DAYS
  end

  def get_meeting_dates(from, to)
    # to can be a date or a number
    _a = center_meeting_days.map{|cmd| cmd.get_dates(from, to)}.flatten
    to.is_a?(Date) ? _a.select{|x| x <= to} : _a[0..(to - 1)]
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
    if meeting_day != :none and (date + number - get_meeting_date(date + number, :previous)).cweek == (date + number).cweek
      (date + number + get_meeting_date(date + number, :next))
    else
      (date + number)
    end
  end

  def previous_meeting_date_from(date)
    number = get_meeting_date(date, :previous)
    if meeting_day != :none and (date - number - get_meeting_date(date - number, :previous)).cweek == (date - number).cweek
      (date - number - get_meeting_date(date - number, :previous))
    else
      (date - number)
    end
  end


  def meeting_day?(date)
    LoanHistory.all(:date => date).aggregate(:center_id).include?(self.id)
  end

  def meeting_time
    meeting_time_hours.two_digits + ':' + meeting_time_minutes.two_digits rescue "00:00"
  end

  def self.paying_today(user, date = Date.today)
    center_ids = LoanHistory.all(:date => date||Date.today).aggregate(:center_id)
    centers = center_ids.blank? ? [] : Center.all(:id => center_ids)
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
  
  def leader=(cid)
    Client.get(cid).make_center_leader rescue false
  end

  def location
    Location.first(:parent_id => self.id, :parent_type => "center")
  end
  
  def self.meeting_today(date=Date.today, user=nil)
    user = User.first
    center_ids = LoanHistory.all(:date => date).aggregate(:center_id)
    # restrict branch manager and center managers to their own branches
    if user.role==:staff_member
      st = user.staff_member
      center_ids = ([st.branches.centers.map{|x| x.id}, st.centers.map{|x| x.id}].flatten.compact) & center_ids
    end
    Center.all(:id => center_ids)
  end
  
  private
  def hours_valid?
    return true if (0..23).include? meeting_time_hours.to_i
    [false, "Hours of the meeting time should be within 0-23"]
  end
  def minutes_valid?
    return true if (0..59).include? meeting_time_minutes.to_i
    [false, "Minutes of the meeting time should be within 0-59"]
  end
  def manager_is_an_active_staff_member?
    return true if manager and manager.active
    [false, "Receiving staff member is currently not active"]
  end

  def handle_meeting_date_change
    # no need to do all this if meeting date was not changed
    return true unless self.meeting_day_change_date

    date = self.meeting_day_change_date

    if not CenterMeetingDay.first(:center => self)
      CenterMeetingDay.create(:center_id => self.id, :valid_from => creation_date||date, :meeting_day => self.meeting_day)
    elsif self.meeting_day != self.meeting_day_for(date)
      if prev_cm = CenterMeetingDay.first(:center_id => self.id, :valid_from.lte => date, :order => [:valid_from.desc])
        # previous CMD should be valid upto date - 1
        prev_cm
        prev_cm.valid_upto = date - 1        
        prev_cm
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
    Center.get(self.id).clients(:fields => [:id, :center_id]).loans.each{|l|
      if [:outstanding, :disbursed].include?(l.status)
        l.update_history
      end
    }
    return true
  end  

  def set_meeting_change_date
    if self.new?
      self.meeting_day_change_date = self.creation_date
    else
      # Check if meeting date was changed. 
      if self.dirty_attributes.map{|x| x.first.name}.include?(:meeting_day)
        if self.meeting_day_change_date.class==String and not self.meeting_day_change_date.blank?
          self.meeting_day_change_date = parse_date(self.meeting_day_change_date)
        else
          # if meeting_day was indeed changed and no meeting_change_date is foudn then set it as today's date
          self.meeting_day_change_date ||= Date.today
        end
      else
        # If meeting_day was not changed then set meeting_day_change_date as nil.
        self.meeting_day_change_date =  nil        
      end
    end
  end

  def get_meeting_date(date, direction)
    number = 1
    if direction == :next
      nwday = (date + number).wday
      while (meet_day = Center.meeting_days.index(meeting_day_for(date + number)) and meet_day > 0 and nwday != meet_day)
        number += 1
        nwday = (date + number).wday
        nwday = 7 if nwday == 0
      end
    else
      nwday = (date - number).wday
      while (meet_day = Center.meeting_days.index(meeting_day_for(date - number)) and meet_day > 0 and nwday != meet_day)
        number += 1
        nwday = (date - number).wday
        nwday = 7 if nwday == 0
      end
    end
    return number
  end

  def convert_blank_to_nil
    self.attributes.each{|k, v|
      if v.is_a?(String) and v.empty? and self.class.properties.find{|x| x.name == k}.type==Integer
        self.send("#{k}=", nil)
      end
    }
  end

end
