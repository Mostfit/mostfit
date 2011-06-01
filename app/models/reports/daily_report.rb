class DailyReport < Report
  attr_accessor :date, :loan_product_id, :branch_id, :staff_member_id, :center_id

  def initialize(params, dates, user)
    @date   =  dates[:date]||Date.today    
    @name   = "Day Report for #{@date}"
    dates[:from_date] = @date
    dates[:to_date] = @date
    @daily_report = ConsolidatedReport.new(params, dates, user)
  end
  
  def name
    "Daily Report for #{@date}"
  end

  def self.name
    "Daily report"
  end

  def headers
    [
     {"Branch / Center"     => [""]}, 
     {"Loan amount"         => ["Applied", "Sanctioned", "Disbursed"]},
     {"Repayment"           => ["Principal", "Interest", "Fee", "Total"]},
     {"Balance outstanding" => ["Principal", "Interest", "Total"]},
     {"Balance overdue"     => ["Principal", "Interest", "Total"]},
     {"Advance repayment"   => ["Collected", "Adjusted", "Balance"]}
    ]
  end
  
  def generate
    return @daily_report.generate
  end
end
