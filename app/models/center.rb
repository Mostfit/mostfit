class Center
  include DataMapper::Resource
  include DateParser

  before :valid?, :convert_blank_to_nil
  before :valid?, :handle_meeting_days
  
  DAYS = [:none, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]

  property :id,                   Serial
  property :name,                 String, :length => 100, :nullable => false, :index => true
  property :code,                 String, :length => 12, :nullable => true, :index => true
  property :address,              Text,   :lazy => true
  property :contact_number,       String, :length => 40, :lazy => true
  property :landmark,             String, :length => 100, :lazy => true  
  property :meeting_day,          Enum.send('[]', *DAYS), :nullable => true, :default => :none, :index => true # DEPRECATED
  property :meeting_time_hours,   Integer, :length => 2, :index => true
  property :meeting_time_minutes, Integer, :length => 2, :index => true
  property :meeting_calendar,     Text # this is a comma separated list of dates and takes precedence over everything else.
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

  def get_meeting_dates(to = SEP_DATE,from = creation_date)
    # DEPRECATED - Please use Center#meeting_dates. get_meeting_dates is non-idiomatic ruby
    meeting_dates(to, from)
  end


  # get a list of meeting dates between from and to if to is a Date. Else gets "to" meeting dates if to is an integer
  # a center must take the responsibility that center_meeting_days never overlap.
  # to can be a date or a number
  def meeting_dates(to = nil,from = nil)
    debugger
    # sometimes loans from another center might be moved to this center. they can be created before this centers creation date
    # therefore, we refer to the loan history table first and if there are no rows there, we refer to the creation date for the 'from' date if none is specified
    min_max_dates = LoanHistory.all(:center_id => self.id).aggregate(:date.min, :date.max)
    from ||= (min_max_dates[0] || self.creation_date)
    to   ||= (min_max_dates[1] || SEP_DATE)
    # first refer to the meeting_calendar
    unless self.meeting_calendar.blank?
      ds = self.meeting_calendar.split(/[\s,]/).reject(&:blank?).map{|d| Date.parse(d) rescue nil}.compact.select{|d| d >= from}.sort
      if to
        ds = ds.select{|d| d <= to} if to.is_a? Date
        ds = ds[0..to - 1] if to.is_a? Numeric
      end
      return ds
    end

    # then check the date vectors
    select = to.class == Date ? {:valid_from.lte => to} : {}
    dvs = center_meeting_days.all(select).map{|cmd| [cmd.valid_from, cmd.date_vector]}.to_hash

    # if from is after the center creation but before the first additional center meeting date then deal with this
    if dvs.blank? or (from < dvs.keys.min and meeting_day != :none)
      dvs[from] =       DateVector.new(1, meeting_day, 1, :week, creation_date, dvs.keys.min || Date.new(2100,12,31))
    end

    # then cycle through this hash and get the appropriate dates
    dates = []
    dvs.keys.sort.each_with_index{|date,i|
      d1 = [date,from].max
      d1 -= 1 if [dvs[date].what].flatten.include?(d1.weekday)
      d2 = dvs.keys.sort[i+1] || (to.class == Date ? to - 1: (to - dates.count - 1))
      _ds = dvs[date].get_dates(d1,d2)
      _ds = _ds[0..(to - dates.count - 1)] if to.class == Fixnum
      dates.concat(_ds)
    }
    dates.sort
  end

  # returns the date vector in use for a given date.
  def date_vector_for(date)
    first_cmd_date = center_meeting_days.aggregate(:valid_from.min) || Date.new(2100,12,31)
    if date < first_cmd_date
      DateVector.new(1, meeting_day, 1, :week, creation_date, first_cmd_date)
    else
      (center_meeting_days.all(:order => [:valid_from]).select{|cmd| cmd.valid_from <= date and cmd.valid_upto >= date}[0]).date_vector
    end
  end

    
  # a simple catalog (Hash) of center names and ids grouped by branches
  # returns some like: {"One branch" => {1 => 'center1', 2 => 'center2'}, "b2" => {3 => 'c3', 4 => 'c4'}} 
  def self.catalog(user=nil)
    result = {}
    branch_names = {}

    if (user or Nothing).staff_member
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



  # returns the meeting day for a given date
  def meeting_day_for(date)
    @meeting_days ||= self.center_meeting_days(:order => [:valid_from])
    if @meeting_days.length==0
      meeting_day
    elsif date_row = @meeting_days.find{|md| md.valid_from <= date and (md.valid_upto == nil or md.valid_upto >= date)} 
      (date_row.meeting_wday)
    elsif @meeting_days[0].valid_from > date
      (@meeting_days[0].meeting_wday)
    else
      (@meeting_days[-1].meeting_wday)
    end
  end
  
  def next_meeting_date_from(date)    
    # first refer to the LoanHistory. Sometimes, some funky loans might be in here and we don't want to depend on center meeting dates in
    # the first instance
    r_date = (LoanHistory.first(:center_id => self.id, :date.gt => date, :order => [:date], :limit => 1) or Nothing).date
    return r_date if r_date
    #oops...no loans in this center. use center_meeting_dates
    debugger
    self.meeting_dates(1, date)[0]
  end
  
  def previous_meeting_date_from(date)
    #likewise for this (see comment above)
    r_date = (LoanHistory.first(:center_id => self.id, :date.lte => date, :order => [:date.desc], :limit => 1) or Nothing).date
    return r_date if r_date
    #oops...no loans in this center. use center_meeting_dates
    self.meeting_dates(date)[-1]
  end


  def meeting_day?(date)
    Center.meeting_days.include?(date)
  end

  def meeting_time
    meeting_time_hours.two_digits + ':' + meeting_time_minutes.two_digits rescue "00:00"
  end

  def self.paying_today(user, date = Date.today, branch_id = nil)
    # returns a list of centers paying today
    selection = {:date => date}.merge(branch_id ? {:branch_id => branch_id} : {})
    center_ids = LoanHistory.all(selection).aggregate(:center_id)
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
    # this makes no sense
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
    [false, "Cannot set #{self.manager.name} as center manager because this staff member is not currently not active"]
  end
  

  def handle_meeting_date_change
    # no need to do all this if meeting date was not changed
    return true unless self.meeting_day_change_date

    date = self.meeting_day_change_date

    if not CenterMeetingDay.first(:center => self)
      # FIXME: This line appears to be failing, because the period attribute is left blank and should be one of %w[week month] probably true in the "elsif" below as well. This means new centers never get a meeting day.
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

  def handle_meeting_days
    # this function creates the first center meeting day for the center when only a meeting day is specified.
    # we will soon deprecate the meeting_day field and work only with center_meeting_days
    if center_meeting_days.blank?
      unless meeting_day == :none
        cmd = CenterMeetingDay.new(:valid_from => nil, :valid_upto => nil, :center_id => self.id, :meeting_day => (meeting_day || :none))
        self.center_meeting_days << cmd
      end
    end

  end

  # def get_meeting_date(date, direction)
  # DEPRECATED. Commenting out right now so that we can restore it if it is being referenced from somewhere
  # TODO remove this from the codebase if nothing borks by 2012-02-28
  #   number = 1
  #   if direction == :next
  #     nwday = (date + number).wday
  #     while (meet_day = Center.meeting_days.index(meeting_day_for(date + number)) and meet_day > 0 and nwday != meet_day)
  #       number += 1
  #       nwday = (date + number).wday
  #       nwday = 7 if nwday == 0
  #     end
  #   else
  #     nwday = (date - number).wday
  #     while (meet_day = Center.meeting_days.index(meeting_day_for(date - number)) and meet_day > 0 and nwday != meet_day)
  #       number += 1
  #       nwday = (date - number).wday
  #       nwday = 7 if nwday == 0
  #     end
  #   end
  #   return number
  # end

  def convert_blank_to_nil
    self.attributes.each{|k, v|
      if v.is_a?(String) and v.empty? and self.class.properties.find{|x| x.name == k}.type==Integer
        self.send("#{k}=", nil)
      end
    }
  end

end
