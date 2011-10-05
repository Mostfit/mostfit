class HolidayCalendar
  include DataMapper::Resource
  
  before :save, :convert_blank_to_nil

  after :save, :update_loan_history

  # Holiday calendars apply to branches, regions and areas.
  # If a holiday calendar applies to a branch, then the holiday calendars that apply to the region and area, NO LONGER APPLY
  # Therefore a holiday calendar may belong only to one of area, region or branch
  
  property :id, Serial
  property :name, String

  property :branch_id, Integer, :nullable => true
  property :region_id, Integer, :nullable => true
  property :area_id,   Integer, :nullable => true
  property :deleted_at, ParanoidDateTime

  belongs_to :region, :area, :branch

  has n, :holidays, :through => Resource

  validates_with_method :must_belong_somewhere

  def branches
    # returns the branches to which this holiday calendar applies
    (Branch.all(:id => branch_id) if branch_id) || (Branch.all(:area_id => area_id) if self.area_id) || (Branch.all('area.region_id' => region_id) if self.region_id)
  end

  def applic
    branch || area || region
  end

  def update_loan_history
    branch_ids = branches.aggregate(:id)
    holidays.each do |holiday|
      Merb.logger.info "Updating branches #{branch_ids.join(',')} for holiday #{holiday.name}"
      LoanHistory.update_holidays(branch_ids, holiday)
    end
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
