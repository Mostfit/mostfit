class LateDisbursalsReport < Report
  attr_accessor :date, :branch, :center, :branch_id, :center_id, :staff_member_id, :loan_product_id

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
    if loan_product_id
      loans = Loan.all(:scheduled_disbursal_date.lte => @date, :disbursal_date => nil, :loan_product_id => loan_product_id) || Loan.all(:approved_on => nil, :loan_product_id => loan_product_id, :rejected_on => nil)
    else
      loans = Loan.all(:scheduled_disbursal_date.lte => @date, :disbursal_date => nil, :rejected_on => nil) || Loan.all(:approved_on => nil, :rejected_on => nil)
    end
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
