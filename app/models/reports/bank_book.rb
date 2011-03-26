class BankBook < Report

  attr_accessor :from_date, :to_date

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Account.all(:account_category => "Bank").map{|a| a.account_earliest_date}.min
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name   = "Bank Book from #{@from_date} to #{@to_date}"
  end


  def generate
    @data = Account.all(:account_category => "Bank")
  end

  def name
    "Bank book from #{from_date} to #{to_date}"
  end

  def self.name
    "Bank book"
  end
  
end
