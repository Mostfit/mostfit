class LateDisbursalsReport < Report
  attr_accessor :date, :branch, :center, :branch_id, :center_id, :staff_member_id

  def initialize(params,dates)
    @date = dates.blank? ? Date.today : dates[:date]
  end

  def name
    "Late disbursals as on #{@date}"
  end

  def self.name
    "Late Disbursals Report"
  end

  def generate
    debugger
    loans = Loan.all(:scheduled_disbursal_date.lte => @date, :disbursal_date => nil)
    centers = loans.clients.centers
    branches = centers.branches
    r = { }
    branches.each do |b|
      r[b] = { }
      centers.select{ |center| center.branch == b }.each do |c|
        r[b][c] =[]
        loans.select{ |l| l.client.center == c}.each do |l|
          r[b][c] << l
        end
      end
    end
    return r
  end
end
