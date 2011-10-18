class HolidayCalendar
  include DataMapper::Resource
  
  before :save, :convert_blank_to_nil
  after :save, :update_loan_history
  
  attr_accessor :old_holidays
  # Holiday calendars apply to branches, regions and areas.
  # If a holiday calendar applies to a branch, then the holiday calendars that apply to the region and area, NO LONGER APPLY
  # Therefore a holiday calendar may belong only to one of area, region or branch
  
  property :id, Serial
  property :name, String

  property :branch_id, Integer, :nullable => true
  property :region_id, Integer, :nullable => true
  property :area_id,   Integer, :nullable => true
  property :deleted_at, ParanoidDateTime

  belongs_to :region
  belongs_to :area
  belongs_to :branch

  has n, :holidays_fors

  validates_with_method :must_belong_somewhere

  def holidays
    holidays_fors.holidays
  end


  def branches
    # returns the branches to which this holiday calendar applies
    (Branch.all(:id => branch_id) if branch_id) || (Branch.all(:area_id => area_id) if self.area_id) || (Branch.all('area.region_id' => region_id) if self.region_id)
  end

  def applic
    branch || area || region
  end


  def update_loan_history()
    debugger
    @old_holidays ||= []
    branch_ids = branches.aggregate(:id)
    # get the loan_ids for the loans affected by deleted holidays
    deleted_holidays = @old_holidays - holidays
    loan_ids = deleted_holidays.map{|holiday| LoanHistory.all(:branch_id => branch_ids, :date => holiday.new_date).aggregate(:loan_id)}.flatten.uniq
    
    # then add the loan_ids for loans affected by new holidays
    new_holidays = holidays - @old_holidays
    loan_ids += new_holidays.map{|holiday| LoanHistory.all(:branch_id => branch_ids, :date => holiday.date).aggregate(:loan_id)}.flatten.uniq
    unless loan_ids.blank?
      # then insert these into the dirty loans list and let the system take care of them
      now = DateTime.now
      repository.adapter.execute(get_bulk_insert_sql("dirty_loans", loan_ids.map{|pl| {:loan_id => pl, :created_at => now}}))
      DirtyLoan.send(:class_variable_set,"@@poke_thread", true)
    end
  end

  def update_unadjusted_holidays
    now = DateTime.now
    branch_ids = branches.aggregate(:id)
    dates = holidays.aggregate(:date)
    loan_ids = LoanHistory.all(:branch_id => branch_ids, :date => dates).aggregate(:loan_id).flatten.uniq
    repository.adapter.execute(get_bulk_insert_sql("dirty_loans", loan_ids.map{|pl| {:loan_id => pl, :created_at => now}}))
    DirtyLoan.send(:class_variable_set,"@@poke_thread", true)
  end

  def add_holiday(holiday)
    holiday = Holiday.get(holiday) if holiday.is_a? Fixnum
    @old_holidays ||= holidays
    self.holidays_fors.push(HolidaysFor.new(:holiday => holiday, :holiday_calendar => self))
  end

  def remove_holiday(holiday)
    holiday = Holiday.get(holiday) unless holiday.is_a? Holiday
    @old_holidays ||= holidays
    HolidaysFor.first(:holiday_calendar => self, :holiday => holiday).destroy
    reload
    update_loan_history
  end

  private
  
  def must_belong_somewhere
    return [false, "Holiday Calendar must belong either to a Region, an Area or a Branch"] unless [branch_id, region_id, area_id].map{|x| x.blank?}.select{|x| not x}.count == 1
    return true
  end

  def convert_blank_to_nil
    self.attributes.each{|k, v|
      if v.is_a?(String) and v.empty? and self.class.properties.find{|x| x.name == k}.type==Integer
        self.send("#{k}=", nil)
      end
    }
  end

    
end

