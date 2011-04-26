class GeneralLedgerReport < Report
  attr_accessor :from_date, :to_date, :account_id, :journal, :posting, :type_of_journal, :branch, :branch_id

  def initialize(params, dates, user)
    current_accounting_period = AccountingPeriod.first(:begin_date.lte => Date.today, :end_date.gte => Date.today)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : (current_accounting_period ? current_accounting_period.begin_date : Date.today - 30)
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : (current_accounting_period ? current_accounting_period.end_date : Date.today)
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
    @data = {}

    if @type_of_journal
      journal_entries = {:date.gte => from_date, :date.lte => to_date, :order => [:date], :journal_type_id => @type_of_journal}
    else
      journal_entries = {:date.gte => from_date, :date.lte => to_date, :order => [:date]}
    end
 
    account = Account.all(:branch_id => @branch_id)

    #   opening_balance = Account.all(params2).postings.journal(:date.lt => from_date).postings(:amount.gte => 0).sum(:amount)
    account.journals(journal_entries).each { |journal|
      @data[journal]  ||= []
      @data[journal][0] = journal.date
      @data[journal][1] = journal.comment
      @data[journal][2] = journal.journal_type.name if journal.journal_type
      @data[journal][3] = journal.transaction_id
      @data[journal][4] = journal.postings(:amount.lt => 0)
      @data[journal][5] = journal.postings(:amount.gt => 0)    
    }
   
    return @data
  end
end
