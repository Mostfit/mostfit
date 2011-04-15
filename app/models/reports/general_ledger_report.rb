class GeneralLedgerReport < Report
  attr_accessor :from_date, :to_date, :account_id, :journal, :posting, :type_of_journal

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : AccountingPeriod.first(:begin_date.lte => Date.today, :end_date.gte => Date.today).begin_date
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : AccountingPeriod.first(:begin_date.lte => Date.today, :end_date.gte => Date.today).end_date
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
    params3 = {:journal_type_id => @type_of_journal}
    if @type_of_journal
      params1 = {:date.gte => from_date, :date.lte => to_date, :order => [:date]}.merge(params3)
    else
      params1 = {:date.gte => from_date, :date.lte => to_date, :order => [:date]}
    end
    params2 = {:id => params.values[0].values[0]}
   
    @data = {}

    if params.values[0].values[0].to_s == ""
      account = Account.all
    else
      account = Account.all(params2)
    end
    #   opening_balance = Account.all(params2).postings.journal(:date.lt => from_date).postings(:amount.gte => 0).sum(:amount)
    account.journals(params1).each { |journal|
      @data[journal]||={}
      @data[journal][0] = journal.date
      @data[journal][1] = journal.comment
      @data[journal][2] = journal.journal_type.name
      @data[journal][3] = journal.transaction_id
      @data[journal][4] = journal.postings(:amount.lt => 0)
      @data[journal][5] = journal.postings(:amount.gt => 0)    
    }
   
    return @data
    
  end
end
