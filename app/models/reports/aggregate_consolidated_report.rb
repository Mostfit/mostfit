class AggregateConsolidatedReport < Report
  attr_accessor :from_date, :to_date, :branch, :center, :branch_id, :center_id, :staff_member_id, :loan_product_id, :group_by_types

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name   = "Report from #{@from_date} to #{@to_date}"    
    get_parameters(params, user)
  end
  
  def group_types
    [:branch, :center, :client_group, :staff_member, :month, :quater, :year]
  end

  def name
    "Aggregate Consolidated Report from #{@from_date} to #{@to_date}"
  end
  
  def self.name
    "Aggregate Consolidated report"
  end
  
  def generate
    group_bys = group_by_types.map{|x| group_types[x]}
    
  end
end
