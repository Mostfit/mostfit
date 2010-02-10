class LateDisbursalsReport < Report
  attr_accessor :date

  def initialize(params,dates)
    @date = dates.blank? ? Date.today : dates
  end

  def name
    "Late disbursals as on #{@date}"
  end

  def self.name
    "Consolidated report"
  end

  def generate
    return Loan.all(:scheduled_disbursal_date.lte => @date, :disbursal_date => nil)
  end
end
