class ClaimReport < Report
  attr_accessor :from_date, :to_date, :branch, :center, :branch_id, :center_id, :staff_member_id, :loan_product_id

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name   = "Report from #{@from_date} to #{@to_date}"
    get_parameters(params, user)
  end

  def self.name
    "Claim Report "
  end

  def generate(params)
   
    Claim.all
 
 end
end
