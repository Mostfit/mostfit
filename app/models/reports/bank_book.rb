class BankBook < Report

  attr_accessor :from_date, :to_date, :branch_id, :bank_account

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name   = "Bank Book from #{@from_date} to #{@to_date}"
    @branch = Branch.get(params[:branch_id]) if params
  end


  def generate
    @data = Account.all(:account_category => "Bank", :branch => @branch)
  end

  def name
    "Bank book from #{from_date} to #{to_date}"
  end

  def self.name
    "Bank book"
  end
  
end
