class DayBook < Report
  attr_accessor :date

  def initialize(params, dates, user)
    @date = (dates and dates[:date]) ? dates[:date] : Date.today
    @name = "Day book as on #{@date}"
    get_parameters(params, user)
  end

  #TODO: Allow user to select particular account
  #TODO: Allow user to select accounts at a particular branch
  #TODO: to pass the actual accounting entries through to let the drill-down
  #TODO: CashBook and BankBook inherit from day book and should simply specify
  #the account_category (Cash|Bank) to fetch instead of filtering out the rest
  #after the fact
  def generate
    date_params = {:date => date}
    journals_on_date = Journal.all(date_params)
    postings_on_date = []
    accounts_hit = []
    journals_on_date.each do |journal|
        journal.postings.each do |posting|
          postings_on_date << posting
          accounts_hit << Account.get(posting.account_id)
        end
    end
    uniq_accounts_hit = accounts_hit.uniq
    day_entries = {}
    uniq_accounts_hit.each do |account|
      for_branch = account.branch ? account.branch : HeadOfficeAccounts::HEAD_OFFICE
      day_entries[for_branch] = {} if day_entries[account.branch].nil?
      day_entries[for_branch][account] = 0.0
      postings_on_date.each do |posting|
        day_entries[for_branch][account] += posting.amount if (posting.account_id == account.id)
      end
    end
    day_entries
  end

  def name
    "Day book for #{date}"
  end

  def self.name
    "Day book"
  end

end

class HeadOfficeAccounts
  attr_reader :name

  def initialize(naam)
    @name = naam
  end

  def <=> (other)
    1
  end

  HEAD_OFFICE = HeadOfficeAccounts.new("Head office")

end