class InsuranceRegister < Report
  attr_accessor :from_date, :to_date

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name   = "Report from #{@from_date} to #{@to_date}"
    get_parameters(params, user)
  end

  def self.name
    "Insurance Register"
  end

  def generate
    params = {:disbursal_date.gte => from_date, :disbursal_date.lte => to_date, 
               :order => [:disbursal_date]}
    loans = Loan.all(params)
    clients = loans.clients
  end
end
