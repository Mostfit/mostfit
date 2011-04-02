class CashBook < Report

  attr_accessor :from_date, :to_date, :branch_id

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Account.all(:account_category => "Cash").map{|a| a.account_earliest_date}.min
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name   = "Cash Book from #{@from_date} to #{@to_date}"
    @branch = Branch.get(params[:branch_id]) if params

  end


  def generate
    @data = Account.all(:account_category => "Cash", :branch => @branch)
  end


  def name
    "Cash book from #{from_date} to #{to_date}"
  end

  def self.name
    "Cash book"
  end
  
end
