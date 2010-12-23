class LateDisbursalsReport < Report
  attr_accessor :date, :branch, :center, :branch_id, :center_id, :staff_member_id, :loan_product_id, :include_unapproved_loans

  def initialize(params,dates, user)
    @date = dates.blank? ? Date.today : dates[:date]
    @name   = "Report from #{@from_date} to #{@to_date}"
    get_parameters(params, user)
  end

  def name
    "Late disbursals as on #{@date}"
  end

  def self.name
    "Late Disbursals Report"
  end

  def generate
    hash_non_disbursed = {:scheduled_disbursal_date.lte => @date, :disbursal_date => nil, :rejected_on => nil}
    hash_non_disbursed[:loan_product_id] = loan_product_id if loan_product_id
    hash_non_disbursed[:approved_on.not]  = nil if not @include_unapproved_loans or @include_unapproved_loans == 0
    loans = Loan.all(hash_non_disbursed)

    r = { }
    @branch.each do |b|
      r[b] = { }
      b.centers.each do |c|
        next if @center and not @center.find{|x| x.id==c.id}        
        r[b][c] =[]
        loans.select{ |l| l.client.center == c}.each do |l|
          r[b][c] << l
        end
      end
    end
    return r
  end
end
