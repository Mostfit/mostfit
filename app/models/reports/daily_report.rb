class DailyReport < Report
  attr_accessor :date, :loan_product_id, :branch_id, :staff_member_id, :center_id
  attr_reader   :data

  include Mostfit::Reporting

  column :'branch / center'
  column :loan_amount         => [:applied,   :sanctioned, :disbursed         ]
  column :repayment           => [:principal, :interest,   :fee,        :total]
  column :balance_outstanding => [:principal, :interest,   :total             ]
  column :balance_overdue     => [:principal, :interest,   :total             ]
  column :advance_repayment   => [:collected, :adjusted,   :balance           ]

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

  def generate
    @data = @daily_report.generate
  end
end
