class GeneralLedgerReport < Report
  attr_accessor :from_date, :to_date,:account_id, :journal,:posting

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.min_date
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name      = "General Ledger"
    get_parameters(params, user)
  end

  def name
    "General Ledger"
  end

  def self.name
    "General Ledger"
  end

  def generate(params)
   
    params1 = {:date.gte => from_date, :date.lte => to_date, :order => [:date]}
    params2 = {:id => params.values[0].values[0]}
   
    @data = {}
    
    #   opening_balance = Account.all(params2).postings.journal(:date.lt => from_date).postings(:amount.gte => 0).sum(:amount)
    Account.all(params2).journals(params1).each { |journal|
      @data[journal]||={}
      @data[journal][0] = journal.date
      @data[journal][1] = journal.comment
      @data[journal][2] = journal.postings(:amount.lt => 0)
      @data[journal][3] = journal.postings(:amount.gt => 0)    
    }
   
    return @data
    
  end
end   
