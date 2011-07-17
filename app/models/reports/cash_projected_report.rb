class CashProjectedReport < Report
  attr_accessor :from_date, :to_date, :branch, :center, :branch_id, :center_id, :staff_member_id, :loan_product_id, :include_past_data
#  validates_with_method :branch_id, :branch_should_be_selected

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today + 1
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today + 7
    @name   = "Projected cash flow from #{@from_date} to #{@to_date}"
    get_parameters(params, user)
 end
  
  def name
    "Projected cash flow from #{@from_date} to #{@to_date}"
  end
  
  def self.name
    "New Cash projection report"
  end
  
  def generate
    (@from_date..@to_date).map do |d|
      hash = {:date => d}
      if @branch_id
        hash[:branch_id] = @branch_id 
        buckets = LoanHistory.all(hash).bucket_by(:center_id, :loan_id)
      else
        buckets = LoanHistory.all(hash).bucket_by(:branch_id, :loan_id)
      end
      buckets.set_dates(:date => d, :date_from => d, :date_to => d + 1)
      [d,buckets.columns([:principal_expected_to_be_received, :interest_expected_to_be_received])]
    end.to_hash
  end
end

      

